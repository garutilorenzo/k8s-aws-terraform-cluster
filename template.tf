resource "aws_launch_template" "k8s_server" {
  name_prefix   = var.k8s_master_template_prefix
  image_id      = var.ami
  instance_type = var.default_instance_type
  user_data     = data.template_cloudinit_config.k8s_server.rendered

  lifecycle {
    create_before_destroy = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.k8s_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      encrypted   = true
    }
  }

  key_name = var.ssk_key_pair_name

  network_interfaces {
    associate_public_ip_address = var.ec2_associate_public_ip_address
    security_groups             = [aws_security_group.k8s-sg.id]
  }

  tags = merge(
    local.tags,
    {
      Name = "template-${var.k8s_master_template_prefix}-${var.environment}"
    }
  )
}

resource "aws_launch_template" "k8s_worker" {
  name_prefix   = var.k8s_worker_template_prefix
  image_id      = var.ami
  instance_type = var.default_instance_type
  user_data     = data.template_cloudinit_config.k8s_worker.rendered

  lifecycle {
    create_before_destroy = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.k8s_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      encrypted   = true
    }
  }

  key_name = var.ssk_key_pair_name

  network_interfaces {
    associate_public_ip_address = var.ec2_associate_public_ip_address
    security_groups             = [aws_security_group.k8s-sg.id]
  }

  tags = merge(
    local.tags,
    {
      Name = "template-${var.k8s_worker_template_prefix}-${var.environment}"
    }
  )
}