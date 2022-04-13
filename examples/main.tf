variable "AWS_ACCESS_KEY" {

}

variable "AWS_SECRET_KEY" {

}

variable "environment" {
  default = "staging"
}

variable "AWS_REGION" {
  default = "<YOUR_REGION>"
}

module "k8s-cluster" {
  ssk_key_pair_name      = "<SSH_KEY_NAME>"
  uuid                   = "<GENERATE_UUID>"
  environment            = var.environment
  vpc_id                 = "<VPC_ID>"
  vpc_private_subnets    = "<PRIVATE_SUBNET_LIST>"
  vpc_public_subnets     = "<PUBLIC_SUBNET_LIST>"
  vpc_subnet_cidr        = "<SUBNET_CIDR>"
  PATH_TO_PUBLIC_LB_CERT = "<PAHT_TO_PUBLIC_LB_CERT>"
  PATH_TO_PUBLIC_LB_KEY  = "<PAHT_TO_PRIVATE_LB_CERT>"
  install_nginx_ingress  = true
  source                 = "github.com/garutilorenzo/k8s-aws-terraform-cluster"
}

output "k8s_dns_name" {
  value = module.k8s-cluster.k8s_dns_name
}

output "k8s_server_private_ips" {
  value = module.k8s-cluster.k8s_server_private_ips
}

output "k8s_workers_private_ips" {
  value = module.k8s-cluster.k8s_workers_private_ips
}