resource "aws_lb" "external-lb" {
  count              = var.install_nginx_ingress ? 1 : 0
  name               = var.k8s_ext_lb_name
  load_balancer_type = "application"
  security_groups    = [aws_security_group.k8s-public-lb[count.index].id]
  internal           = "false"
  subnets            = var.vpc_public_subnets

  enable_cross_zone_load_balancing = true

  tags = merge(
    local.tags,
    {
      Name = "${var.k8s_ext_lb_name}-${var.environment}"
    }
  )

}

# HTTP
resource "aws_lb_listener" "external-lb-listener-http" {
  count             = var.install_nginx_ingress ? 1 : 0
  load_balancer_arn = aws_lb.external-lb[count.index].arn

  protocol = "HTTP"
  port     = var.extlb_http_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-lb-tg-http[count.index].arn
  }

  tags = merge(
    local.tags,
    {
      Name = "lb-http-listener-${var.k8s_ext_lb_name}-${var.environment}"
    }
  )
}

resource "aws_lb_target_group" "external-lb-tg-http" {
  count    = var.install_nginx_ingress ? 1 : 0
  port     = var.extlb_listener_http_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id


  depends_on = [
    aws_lb.external-lb
  ]

  health_check {
    protocol = "HTTP"
    path     = "/healthz"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "lb-http-tg-${var.k8s_ext_lb_name}-${var.environment}"
    }
  )
}

resource "aws_autoscaling_attachment" "target-http" {
  count = var.install_nginx_ingress ? 1 : 0
  depends_on = [
    aws_autoscaling_group.k8s_workers_asg,
    aws_lb_target_group.external-lb-tg-http
  ]

  autoscaling_group_name = aws_autoscaling_group.k8s_workers_asg.name
  lb_target_group_arn    = aws_lb_target_group.external-lb-tg-http[count.index].arn
}

# HTTPS
resource "aws_lb_listener" "external-lb-listener-https" {
  count             = var.install_nginx_ingress ? 1 : 0
  load_balancer_arn = aws_lb.external-lb[count.index].arn

  protocol        = "HTTPS"
  port            = var.extlb_https_port
  certificate_arn = aws_acm_certificate.cert[count.index].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external-lb-tg-https[count.index].arn
  }

  tags = merge(
    local.tags,
    {
      Name = "lb-https-listener-${var.k8s_ext_lb_name}-${var.environment}"
    }
  )
}

resource "aws_lb_target_group" "external-lb-tg-https" {
  count    = var.install_nginx_ingress ? 1 : 0
  port     = var.extlb_listener_https_port
  protocol = "HTTPS"
  vpc_id   = var.vpc_id


  depends_on = [
    aws_lb.external-lb
  ]

  health_check {
    protocol = "HTTPS"
    path     = "/healthz"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "lb-https-tg-${var.k8s_ext_lb_name}-${var.environment}"
    }
  )
}

resource "aws_autoscaling_attachment" "target-https" {
  count = var.install_nginx_ingress ? 1 : 0
  depends_on = [
    aws_autoscaling_group.k8s_workers_asg,
    aws_lb_target_group.external-lb-tg-https
  ]

  autoscaling_group_name = aws_autoscaling_group.k8s_workers_asg.name
  lb_target_group_arn    = aws_lb_target_group.external-lb-tg-https[count.index].arn
}