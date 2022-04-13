resource "aws_iam_instance_profile" "k8s_instance_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.k8s_iam_role.name

  tags = merge(
    local.tags,
    {
      Name = "k8s-instance-pofile-${var.environment}"
    }
  )

}

resource "aws_iam_role" "k8s_iam_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "k8s-iam-role-${var.environment}"
    }
  )

}

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "S3BucketPolicy"
  path        = "/"
  description = "S3 Bucket Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.k8s_cert_bucket.arn}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "${aws_s3_bucket.k8s_cert_bucket.arn}/*"
        ]
      },
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "k8s-s3-bucket-policy-${var.environment}"
    }
  )
}

# resource "aws_iam_policy" "cluster_autoscaler" {
#   name        = "ClusterAutoscalerPolicy"
#   path        = "/"
#   description = "Cluster autoscaler policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "autoscaling:DescribeAutoScalingGroups",
#           "autoscaling:DescribeAutoScalingInstances",
#           "autoscaling:DescribeLaunchConfigurations",
#           "autoscaling:SetDesiredCapacity",
#           "autoscaling:TerminateInstanceInAutoScalingGroup",
#           "autoscaling:DescribeTags",
#           "ec2:DescribeLaunchTemplateVersions"
#         ],
#         Resource = [
#           "*"
#         ]
#       }
#     ]
#   })

#   tags = {
#     environment = "${var.environment}"
#     provisioner = "terraform"
#   }
# }

resource "aws_iam_role_policy_attachment" "attach_ec2_ro_policy" {
  role       = aws_iam_role.k8s_iam_role.name
  policy_arn = data.aws_iam_policy.AmazonEC2ReadOnlyAccess.arn
}

resource "aws_iam_role_policy_attachment" "attach_s3_bucket_policy" {
  role       = aws_iam_role.k8s_iam_role.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}