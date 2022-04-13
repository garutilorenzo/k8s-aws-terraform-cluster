resource "aws_lb" "k8s-server-lb" {
  name               = var.k8s_internal_lb_name
  load_balancer_type = "network"
  internal           = "true"
  subnets            = var.vpc_private_subnets

  enable_cross_zone_load_balancing = true

  tags = merge(
    local.tags,
    {
      Name = "lb-${var.k8s_internal_lb_name}-${var.environment}"
    }
  )
}

resource "aws_lb_listener" "k8s-server-listener" {
  load_balancer_arn = aws_lb.k8s-server-lb.arn

  protocol = "TCP"
  port     = var.kube_api_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s-server-tg.arn
  }

  tags = merge(
    local.tags,
    {
      Name = "lb-listener-${var.k8s_internal_lb_name}-${var.environment}"
    }
  )
}

resource "aws_lb_target_group" "k8s-server-tg" {
  port               = var.kube_api_port
  protocol           = "TCP"
  vpc_id             = var.vpc_id
  preserve_client_ip = false

  depends_on = [
    aws_lb.k8s-server-lb
  ]

  health_check {
    protocol = "TCP"
    interval = 10
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "target" {

  depends_on = [
    aws_autoscaling_group.k8s_servers_asg,
    aws_lb_target_group.k8s-server-tg
  ]

  autoscaling_group_name = aws_autoscaling_group.k8s_servers_asg.name
  lb_target_group_arn    = aws_lb_target_group.k8s-server-tg.arn
}