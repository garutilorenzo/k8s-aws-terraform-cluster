locals {
  tags = {
    "environment" = "${var.environment}"
    "provisioner" = "terraform"
    "scope"       = "k8s-cluster"
    "uuid"        = "${var.uuid}"
  }
}