variable "environment" {
  type = string
}

variable "uuid" {
  type = string
}

variable "ssk_key_pair_name" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "The vpc id"
}

variable "vpc_private_subnets" {
  type        = list(any)
  description = "The private vpc subnets ids"
}

variable "vpc_public_subnets" {
  type        = list(any)
  description = "The public vpc subnets ids"
}

variable "vpc_subnet_cidr" {
  type        = string
  description = "VPC subnet CIDR"
}

variable "ec2_associate_public_ip_address" {
  type    = bool
  default = false
}

variable "s3_bucket_name" {
  type    = string
  default = "my-very-secure-k8s-bucket"
}

variable "instance_profile_name" {
  type    = string
  default = "K8sInstanceProfile"
}

variable "iam_role_name" {
  type    = string
  default = "K8sIamRole"
}

variable "ami" {
  type    = string
  default = "ami-0a2616929f1e63d91"
}

variable "default_instance_type" {
  type    = string
  default = "t3.large"
}

variable "instance_types" {
  description = "List of instance types to use"
  type        = map(string)
  default = {
    asg_instance_type_1 = "t3.large"
    asg_instance_type_2 = "t2.large"
    asg_instance_type_3 = "m4.large"
    asg_instance_type_4 = "t3a.large"
  }
}

variable "k8s_master_template_prefix" {
  type    = string
  default = "k8s_master_tpl"
}

variable "k8s_worker_template_prefix" {
  type    = string
  default = "k8s_worker_tpl"
}

variable "k8s_version" {
  type    = string
  default = "1.23.5"
}

variable "k8s_pod_subnet" {
  type    = string
  default = "10.244.0.0/16"
}

variable "k8s_service_subnet" {
  type    = string
  default = "10.96.0.0/12"
}

variable "k8s_dns_domain" {
  type    = string
  default = "cluster.local"
}

variable "kube_api_port" {
  type        = number
  default     = 6443
  description = "Kubeapi Port"
}

variable "k8s_internal_lb_name" {
  type    = string
  default = "k8s-server-tcp-lb"
}

variable "k8s_server_desired_capacity" {
  type        = number
  default     = 3
  description = "k8s server ASG desired capacity"
}

variable "k8s_server_min_capacity" {
  type        = number
  default     = 3
  description = "k8s server ASG min capacity"
}

variable "k8s_server_max_capacity" {
  type        = number
  default     = 4
  description = "k8s server ASG max capacity"
}

variable "k8s_worker_desired_capacity" {
  type        = number
  default     = 3
  description = "k8s server ASG desired capacity"
}

variable "k8s_worker_min_capacity" {
  type        = number
  default     = 3
  description = "k8s server ASG min capacity"
}

variable "k8s_worker_max_capacity" {
  type        = number
  default     = 4
  description = "k8s server ASG max capacity"
}

variable "cluster_name" {
  type        = string
  default     = "k8s-cluster"
  description = "Cluster name"
}


variable "PATH_TO_PUBLIC_LB_CERT" {
  type        = string
  description = "Path to the public LB https certificate"
}

variable "PATH_TO_PUBLIC_LB_KEY" {
  type        = string
  description = "Path to the public LB key"
}

variable "install_longhorn" {
  type    = bool
  default = false
}

variable "longhorn_release" {
  type    = string
  default = "v1.2.3"
}

variable "install_nginx_ingress" {
  type        = bool
  default     = false
  description = "Create external LB true/false"
}

variable "k8s_ext_lb_name" {
  type    = string
  default = "k8s-ext-lb"
}

variable "extlb_listener_http_port" {
  type    = number
  default = 30080
}

variable "extlb_listener_https_port" {
  type    = number
  default = 30443
}

variable "extlb_http_port" {
  type    = number
  default = 80
}

variable "extlb_https_port" {
  type    = number
  default = 443
}