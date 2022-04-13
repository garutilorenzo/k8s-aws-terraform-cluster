resource "aws_autoscaling_group" "k8s_servers_asg" {
  name                      = "k8s_servers"
  wait_for_capacity_timeout = "5m"
  vpc_zone_identifier       = var.vpc_private_subnets

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 20
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.k8s_server.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type     = override.value
          weighted_capacity = "1"
        }
      }

    }
  }

  desired_capacity          = var.k8s_server_desired_capacity
  min_size                  = var.k8s_server_min_capacity
  max_size                  = var.k8s_server_max_capacity
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true

  tag {
    key                 = "provisioner"
    value               = "terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s-instance-type"
    value               = "k8s-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "uuid"
    value               = var.uuid
    propagate_at_launch = true
  }

  tag {
    key                 = "scope"
    value               = "k8s-cluster"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "k8s-server-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = ""
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "k8s_workers_asg" {
  name                = "k8s_workers"
  vpc_zone_identifier = var.vpc_private_subnets

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 20
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.k8s_worker.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.instance_types
        content {
          instance_type     = override.value
          weighted_capacity = "1"
        }
      }
    }
  }

  desired_capacity          = var.k8s_worker_desired_capacity
  min_size                  = var.k8s_worker_min_capacity
  max_size                  = var.k8s_worker_max_capacity
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true

  tag {
    key                 = "provisioner"
    value               = "terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s-instance-type"
    value               = "k8s-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "uuid"
    value               = var.uuid
    propagate_at_launch = true
  }

  tag {
    key                 = "scope"
    value               = "k8s-cluster"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "k8s-worker-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = ""
    propagate_at_launch = true
  }
}