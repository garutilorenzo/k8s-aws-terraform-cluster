data "aws_iam_policy" "AmazonEC2ReadOnlyAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

data "template_cloudinit_config" "k8s_server" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/files/cloud-config-base.yaml", {})
  }

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/files/install_k8s_utils.sh", { k8s_version = var.k8s_version, install_longhorn = var.install_longhorn, })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/install_k8s.sh", {
      is_k8s_server             = true,
      k8s_version               = var.k8s_version,
      k8s_dns_domain            = var.k8s_dns_domain,
      k8s_pod_subnet            = var.k8s_pod_subnet,
      k8s_service_subnet        = var.k8s_service_subnet,
      s3_bucket_name            = var.s3_bucket_name,
      kube_api_port             = var.kube_api_port,
      control_plane_url         = aws_lb.k8s-server-lb.dns_name,
      install_longhorn          = var.install_longhorn,
      longhorn_release          = var.longhorn_release,
      install_nginx_ingress     = var.install_nginx_ingress,
      extlb_listener_http_port  = var.extlb_listener_http_port,
      extlb_listener_https_port = var.extlb_listener_https_port,
    })
  }
}

data "template_cloudinit_config" "k8s_worker" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/files/cloud-config-base.yaml", {})
  }

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/files/install_k8s_utils.sh", { k8s_version = var.k8s_version, install_longhorn = var.install_longhorn })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/install_k8s_worker.sh", {
      is_k8s_server     = false,
      s3_bucket_name    = var.s3_bucket_name,
      kube_api_port     = var.kube_api_port,
      control_plane_url = aws_lb.k8s-server-lb.dns_name,
    })
  }
}

data "aws_instances" "k8s_servers" {

  depends_on = [
    aws_autoscaling_group.k8s_servers_asg,
  ]

  instance_tags = {
    k8s-instance-type = "k8s-server"
    provisioner       = "terraform"
    environment       = var.environment
    uuid              = var.uuid
    scope             = "k8s-cluster"
  }

  instance_state_names = ["running"]
}

data "aws_instances" "k8s_workers" {

  depends_on = [
    aws_autoscaling_group.k8s_workers_asg,
  ]

  instance_tags = {
    k8s-instance-type = "k8s-worker"
    provisioner       = "terraform"
    environment       = var.environment
    uuid              = var.uuid
    scope             = "k8s-cluster"
  }

  instance_state_names = ["running"]
}