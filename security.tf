resource "aws_security_group" "k8s-sg" {
  vpc_id      = var.vpc_id
  name        = "k8s-sg"
  description = "Kubernetes ingress rules"

  lifecycle {
    create_before_destroy = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_subnet_cidr]
  }

  ingress {
    from_port   = var.kube_api_port
    to_port     = var.kube_api_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_subnet_cidr]
  }

  ingress {
    from_port   = var.extlb_listener_http_port
    to_port     = var.extlb_listener_http_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_subnet_cidr]
  }

  ingress {
    from_port   = var.extlb_listener_https_port
    to_port     = var.extlb_listener_https_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_subnet_cidr]
  }

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }

  tags = merge(
    local.tags,
    {
      Name = "sg-k8s-cluster-${var.environment}"
    }
  )
}

resource "aws_security_group" "k8s-public-lb" {
  count       = var.install_nginx_ingress ? 1 : 0
  vpc_id      = var.vpc_id
  name        = "k8s-public-lb"
  description = "Kubernetes public LB ingress rules"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.extlb_http_port
    to_port     = var.extlb_http_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.extlb_https_port
    to_port     = var.extlb_https_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "k8s-cluster-public-lb${var.environment}"
    }
  )
}