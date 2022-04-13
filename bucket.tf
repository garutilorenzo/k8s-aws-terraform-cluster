resource "aws_s3_bucket" "k8s_cert_bucket" {
  bucket = var.s3_bucket_name

  tags = merge(
    local.tags,
    {
      Name = "k8s-s3-bucket-${var.environment}"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "k8s_cert_bucket_access_block" {
  bucket = aws_s3_bucket.k8s_cert_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}