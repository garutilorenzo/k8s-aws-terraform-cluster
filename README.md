[![GitHub issues](https://img.shields.io/github/issues/garutilorenzo/k8s-aws-terraform-cluster)](https://github.com/garutilorenzo/k8s-aws-terraform-cluster/issues)
![GitHub](https://img.shields.io/github/license/garutilorenzo/k8s-aws-terraform-cluster)
[![GitHub forks](https://img.shields.io/github/forks/garutilorenzo/k8s-aws-terraform-cluster)](https://github.com/garutilorenzo/k8s-aws-terraform-cluster/network)
[![GitHub stars](https://img.shields.io/github/stars/garutilorenzo/k8s-aws-terraform-cluster)](https://github.com/garutilorenzo/k8s-aws-terraform-cluster/stargazers)

<p align="center">
  <img src="https://garutilorenzo.github.io/images/k8s-logo.png?" alt="k8s Logo"/>
</p>

# Deploy Kubernetes on Amazon AWS

Deploy in a few minutes an high available Kubernetes cluster on Amazon AWS using mixed on-demand and spot instances.

Please **note**, this is only an examle on how to Deploy a Kubernetes cluster. For a production environment you should use [EKS](https://aws.amazon.com/eks/) or [ECS](https://aws.amazon.com/it/ecs/).

The scope of this repo si to show all the AWS components needed to deploy a high available K8s cluster.

# Table of Contents

* [Requirements](#requirements)
* [Infrastructure overview](#infrastructure-overview)
* [Before you start](#before-you-start)
* [Project setup](#project-setup)
* [AWS provider setup](#aws-provider-setup)
* [Pre flight checklist](#pre-flight-checklist)
* [Deploy](#deploy)
* [Deploy a sample stack](#deploy-a-sample-stack)
* [Clean up](#clean-up)
* [Todo](#todo)

## Requirements

* [Terraform](https://www.terraform.io/) - Terraform is an open-source infrastructure as code software tool that provides a consistent CLI workflow to manage hundreds of cloud services. Terraform codifies cloud APIs into declarative configuration files.
* [Amazon AWS Account](https://aws.amazon.com/it/console/) - Amazon AWS account with billing enabled
* [kubectl](https://kubernetes.io/docs/tasks/tools/) - The Kubernetes command-line tool (optional)
* [aws cli](https://aws.amazon.com/cli/) optional

You need also:

* one VPC with private and public subnets
* one ssh key already uploaded on your AWS account
* one bastion host to reach all the private EC2 instances

For VPC and bastion host you can refer to [this](https://github.com/garutilorenzo/aws-terraform-examples) repository.

## Infrastructure overview

The final infrastructure will be made by:

* two autoscaling group, one for the kubernetes master nodes and one for the worker nodes
* two launch template, used by the asg
* one internal load balancer (L4) that will route traffic to Kubernetes servers
* one external load balancer (L7) that will route traffic to Kubernetes workers
* one security group that will allow traffic from the VPC subnet CIDR on all the k8s ports (kube api, nginx ingress node port etc)
* one security group that will allow traffic from all the internet into the public load balancer (L7) on port 80 and 443
* one S3 bucket, used to store the cluster join certificates
* one IAM role, used to allow all the EC2 instances in the cluster to write on the S3 bucket, used to share the join certificates
* one certificate used by the public LB, stored on AWS ACM. The certificate is a self signed certificate.

![k8s infra](https://garutilorenzo.github.io/images/k8s-infra.png?)

## Kubernetes setup

The installation of K8s id done by [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/). In this installation [Containerd](https://containerd.io/) is used as CRI and [flannel](https://github.com/flannel-io/flannel) is used as CNI.

You can optionally install [Nginx ingress controller](https://kubernetes.github.io/ingress-nginx/) and [Longhorn](#https://longhorn.io/).

To install Nginx ingress set the variable *install_nginx_ingress* to yes (default no). To install longhorn set the variable *install_longhorn* to yes (default no). **NOTE** if you don't install the nginx ingress, the public Load Balancer and the SSL certificate won't be deployed.

In this installation is used a S3 bucket to store the join certificate/token. At the first startup of the instance, if the cluster does not exist, the S3 bucket is used to get the join certificates/token.

## Before you start

Note that this tutorial uses AWS resources that are outside the AWS free tier, so be careful!

## Project setup

Clone this repo and go in the example/ directory:

```
git clone https://github.com/garutilorenzo/k8s-aws-terraform-cluster
cd k8s-aws-terraform-cluster/example/
```

Now you have to edit the main.tf file and you have to create the terraform.tfvars file. For more detail see [AWS provider setup](#aws-provider-setup) and [Pre flight checklist](#pre-flight-checklist).

Or if you prefer you can create an new empty directory in your workspace and create this three files:

* terraform.tfvars
* main.tf
* provider.tf

The main.tf file will look like:

```
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
```

For all the possible variables see [Pre flight checklist](#pre-flight-checklist)

The provider.tf will look like:

```
provider "aws" {
  region     = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}
```

The terraform.tfvars will look like:

```
AWS_ACCESS_KEY = "xxxxxxxxxxxxxxxxx"
AWS_SECRET_KEY = "xxxxxxxxxxxxxxxxx"
```

Now we can init terraform with:

```
terraform init

Initializing modules...
- k8s-cluster in ..

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/template...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/template v2.2.0...
- Installed hashicorp/template v2.2.0 (signed by HashiCorp)
- Installing hashicorp/aws v4.9.0...
- Installed hashicorp/aws v4.9.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### Generate self signed SSL certificate for the public LB (L7)

**NOTE** If you already own a valid certificate skip this step and set the correct values for the variables: PATH_TO_PUBLIC_LB_CERT and PATH_TO_PUBLIC_LB_KEY

We need to generate the certificates (sel signed) for our public load balancer (Layer 7). To do this we need *openssl*, open a terminal and follow this step:

Generate the key:

```
openssl genrsa 2048 > privatekey.pem
Generating RSA private key, 2048 bit long modulus (2 primes)
.......+++++
...............+++++
e is 65537 (0x010001)
```

Generate the a new certificate request:

```
openssl req -new -key privatekey.pem -out csr.pem
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:IT
State or Province Name (full name) [Some-State]:Italy
Locality Name (eg, city) []:Brescia
Organization Name (eg, company) [Internet Widgits Pty Ltd]:GL Ltd
Organizational Unit Name (eg, section) []:IT
Common Name (e.g. server FQDN or YOUR name) []:testlb.domainexample.com
Email Address []:email@you.com

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```

Generate the public CRT:

```
openssl x509 -req -days 365 -in csr.pem -signkey privatekey.pem -out public.crt
Signature ok
subject=C = IT, ST = Italy, L = Brescia, O = GL Ltd, OU = IT, CN = testlb.domainexample.com, emailAddress = email@you.com
Getting Private key
```

This is the final result:

```
ls

csr.pem  privatekey.pem  public.crt
```

Now set the variables:

* PATH_TO_PUBLIC_LB_CERT: ~/full_path/public.crt
* PATH_TO_PUBLIC_LB_KEY: ~/full_path/privatekey.pem

## AWS provider setup

Follow the prerequisites step on [this](https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started) link.
In your workspace folder or in the examples directory of this repo create a file named terraform.tfvars:

```
AWS_ACCESS_KEY = "xxxxxxxxxxxxxxxxx"
AWS_SECRET_KEY = "xxxxxxxxxxxxxxxxx"
```

## Pre flight checklist

Once you have created the terraform.tfvars file edit the main.tf file (always in the example/ directory) and set the following variables:

| Var   | Required | Desc |
| ------- | ------- | ----------- |
| `region`       | `yes`       | set the correct OCI region based on your needs  |
| `environment`  | `yes`  | Current work environment (Example: staging/dev/prod). This value is used for tag all the deployed resources |
| `uuid`  | `yes`  | UUID used to tag all resources |
| `ssk_key_pair_name`  | `yes`  | Name of the ssh key to use |
| `vpc_id`  | `yes`  |  ID of the VPC to use. You can find your vpc_id in your AWS console (Example: vpc-xxxxx) |
| `vpc_private_subnets`  | `yes`  |  List of private subnets to use. This subnets are used for the public LB You can find the list of your vpc subnets in your AWS console (Example: subnet-xxxxxx) |
| `vpc_public_subnets`   | `yes`  |  List of public subnets to use. This subnets are used for the EC2 instances and the private LB. You can find the list of your vpc subnets in your AWS console (Example: subnet-xxxxxx) |
| `vpc_subnet_cidr`  | `yes`  |  Your subnet CIDR. You can find the VPC subnet CIDR in your AWS console (Example: 172.31.0.0/16) |
| `PATH_TO_PUBLIC_LB_CERT`  | `yes`  | Path to the public LB certificate. See [how to](#generate-self-signed-ssl-certificate-for-the-public-lb-l7) generate the certificate |
| `PATH_TO_PUBLIC_LB_KEY`  | `yes`  | Path to the public LB key. See [how to](#generate-self-signed-ssl-certificate-for-the-public-lb-l7) generate the key |
| `ec2_associate_public_ip_address`  | `no`  |  Assign or not a pulic ip to the EC2 instances. Default: false |
| `s3_bucket_name`  | `no`  |  S3 bucket name used for sharing the kubernetes token used for joining the cluster. Default: my-very-secure-k8s-bucket |
| `instance_profile_name`  | `no`  | Instance profile name. Default: K8sInstanceProfile |
| `iam_role_name`  | `no`  | IAM role name. Default: K8sIamRole |
| `ami`  | `no`  | Ami image name. Default: ami-0a2616929f1e63d91, ubuntu 20.04 |
| `default_instance_type`  | `no`  | Default instance type used by the Launch template. Default: t3.large |
| `instance_types`  | `no`  | Array of instances used by the ASG. Dfault: { asg_instance_type_1 = "t3.large", asg_instance_type_3 = "m4.large", asg_instance_type_4 = "t3a.large" } |
| `k8s_master_template_prefix`  | `no`  | Template prefix for the master instances. Default: k8s_master_tpl |
| `k8s_worker_template_prefix`  | `no`  | Template prefix for the worker instances. Default: k8s_worker_tpl  |
| `k8s_version`  | `no`  | Kubernetes version to install  |
| `k8s_pod_subnet`  | `no`  | Kubernetes pod subnet managed by the CNI (Flannel). Default: 10.244.0.0/16 |
| `k8s_service_subnet`  | `no`  | Kubernetes pod service managed by the CNI (Flannel). Default: 10.96.0.0/12 |
| `k8s_dns_domain`  | `no`  | Internal kubernetes DNS domain. Default: cluster.local |
| `kube_api_port`  | `no`  | Kubernetes api port. Default: 6443 |
| `k8s_internal_lb_name`  | `no`  | Internal load balancer name. Default: k8s-server-tcp-lb |
| `k8s_server_desired_capacity` | `no`        | Desired number of k8s servers. Default 3 |
| `k8s_server_min_capacity` | `no`        | Min number of k8s servers: Default 4 |
| `k8s_server_max_capacity` | `no`        |  Max number of k8s servers: Default 3 |
| `k8s_worker_desired_capacity` | `no`        | Desired number of k8s workers. Default 3 |
| `k8s_worker_min_capacity` | `no`        | Min number of k8s workers: Default 4 |
| `k8s_worker_max_capacity` | `no`        | Max number of k8s workers: Default 3 |
| `cluster_name`  | `no`  | Kubernetes cluster name. Default: k8s-cluster |
| `install_longhorn`  | `no`  | Install or not longhorn. Default: false |
| `longhorn_release`  | `no`  | longhorn release. Default: v1.2.3 |
| `install_nginx_ingress`  | `no`  | Install or not nginx ingress controller. Default: false |
| `k8s_ext_lb_name`  | `no`  | External load balancer name. Default: k8s-ext-lb |
| `extlb_listener_http_port`  | `no`  | HTTP nodeport where nginx ingress controller will listen. Default: 30080 |
| `extlb_listener_https_port`  | `no`  | HTTPS nodeport where nginx ingress controller will listen. Default 30443 |
| `extlb_http_port`  | `no`  | External LB HTTP listen port. Default: 80 |
| `extlb_https_port`  | `no`  | External LB HTTPS listen port. Default 443 |

## Deploy

We are now ready to deploy our infrastructure. First we ask terraform to plan the execution with:

```
terraform plan

...
...
      + name                   = "k8s-sg"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags                   = {
          + "Name"        = "sg-k8s-cluster-staging"
          + "environment" = "staging"
          + "provisioner" = "terraform"
          + "scope"       = "k8s-cluster"
          + "uuid"        = "xxxxx-xxxxx-xxxx-xxxxxx-xxxxxx"
        }
      + tags_all               = {
          + "Name"        = "sg-k8s-cluster-staging"
          + "environment" = "staging"
          + "provisioner" = "terraform"
          + "scope"       = "k8s-cluster"
          + "uuid"        = "xxxxx-xxxxx-xxxx-xxxxxx-xxxxxx"
        }
      + vpc_id                 = "vpc-xxxxxx"
    }

Plan: 25 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + k8s_dns_name            = (known after apply)
  + k8s_server_private_ips  = [
      + (known after apply),
    ]
  + k8s_workers_private_ips = [
      + (known after apply),
    ]

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

now we can deploy our resources with:

```
terraform apply

...

      + tags_all               = {
          + "Name"        = "sg-k8s-cluster-staging"
          + "environment" = "staging"
          + "provisioner" = "terraform"
          + "scope"       = "k8s-cluster"
          + "uuid"        = "xxxxx-xxxxx-xxxx-xxxxxx-xxxxxx"
        }
      + vpc_id                 = "vpc-xxxxxxxx"
    }

Plan: 25 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + k8s_dns_name            = (known after apply)
  + k8s_server_private_ips  = [
      + (known after apply),
    ]
  + k8s_workers_private_ips = [
      + (known after apply),
    ]

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

...
...

Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:

k8s_dns_name = "k8s-ext-<REDACTED>.elb.amazonaws.com"
k8s_server_private_ips = [
  tolist([
    "172.x.x.x",
    "172.x.x.x",
    "172.x.x.x",
  ]),
]
k8s_workers_private_ips = [
  tolist([
    "172.x.x.x",
    "172.x.x.x",
    "172.x.x.x",
  ]),
]
```
Now on one master node you can check the status of the cluster with:

```
ssh -j bastion@<BASTION_IP> ubuntu@172.x.x.x

Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.13.0-1021-aws x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Wed Apr 13 12:41:52 UTC 2022

  System load:  0.52               Processes:             157
  Usage of /:   17.8% of 19.32GB   Users logged in:       0
  Memory usage: 11%                IPv4 address for cni0: 10.244.0.1
  Swap usage:   0%                 IPv4 address for ens3: 172.68.4.237


0 updates can be applied immediately.


Last login: Wed Apr 13 12:40:32 2022 from 172.68.0.6
ubuntu@i-04d089ed896cfafe1:~$ sudo su -

root@i-04d089ed896cfafe1:~# kubectl get nodes
NAME                  STATUS   ROLES                  AGE     VERSION
i-0033b408f7a1d55f3   Ready    control-plane,master   3m33s   v1.23.5
i-0121c2149821379cc   Ready    <none>                 4m16s   v1.23.5
i-04d089ed896cfafe1   Ready    control-plane,master   4m53s   v1.23.5
i-072bf7de2e94e6f2d   Ready    <none>                 4m15s   v1.23.5
i-09b23242f40eabcca   Ready    control-plane,master   3m56s   v1.23.5
i-0cb1e2e7784768b22   Ready    <none>                 3m57s   v1.23.5

root@i-04d089ed896cfafe1:~# kubectl get ns
NAME              STATUS   AGE
default           Active   5m18s
ingress-nginx     Active   111s # <- ingress controller ns
kube-node-lease   Active   5m19s
kube-public       Active   5m19s
kube-system       Active   5m19s
longhorn-system   Active   109s  # <- longhorn ns

root@i-04d089ed896cfafe1:~# kubectl get pods --all-namespaces
NAMESPACE         NAME                                          READY   STATUS      RESTARTS        AGE
ingress-nginx     ingress-nginx-admission-create-v2fpx          0/1     Completed   0               2m33s
ingress-nginx     ingress-nginx-admission-patch-54d9f           0/1     Completed   0               2m33s
ingress-nginx     ingress-nginx-controller-7fc8d55869-cxv87     1/1     Running     0               2m33s
kube-system       coredns-64897985d-8cg8g                       1/1     Running     0               5m46s
kube-system       coredns-64897985d-9v2r8                       1/1     Running     0               5m46s
kube-system       etcd-i-0033b408f7a1d55f3                      1/1     Running     0               4m33s
kube-system       etcd-i-04d089ed896cfafe1                      1/1     Running     0               5m42s
kube-system       etcd-i-09b23242f40eabcca                      1/1     Running     0               5m
kube-system       kube-apiserver-i-0033b408f7a1d55f3            1/1     Running     1 (4m30s ago)   4m30s
kube-system       kube-apiserver-i-04d089ed896cfafe1            1/1     Running     0               5m46s
kube-system       kube-apiserver-i-09b23242f40eabcca            1/1     Running     0               5m1s
kube-system       kube-controller-manager-i-0033b408f7a1d55f3   1/1     Running     0               4m36s
kube-system       kube-controller-manager-i-04d089ed896cfafe1   1/1     Running     1 (4m50s ago)   5m49s
kube-system       kube-controller-manager-i-09b23242f40eabcca   1/1     Running     0               5m1s
kube-system       kube-flannel-ds-7c65s                         1/1     Running     0               5m2s
kube-system       kube-flannel-ds-bb842                         1/1     Running     0               4m10s
kube-system       kube-flannel-ds-q27gs                         1/1     Running     0               5m21s
kube-system       kube-flannel-ds-sww7p                         1/1     Running     0               5m3s
kube-system       kube-flannel-ds-z8h5p                         1/1     Running     0               5m38s
kube-system       kube-flannel-ds-zrwdq                         1/1     Running     0               5m22s
kube-system       kube-proxy-6rbks                              1/1     Running     0               5m2s
kube-system       kube-proxy-9npgg                              1/1     Running     0               5m21s
kube-system       kube-proxy-px6br                              1/1     Running     0               5m3s
kube-system       kube-proxy-q9889                              1/1     Running     0               4m10s
kube-system       kube-proxy-s5qnv                              1/1     Running     0               5m22s
kube-system       kube-proxy-tng4x                              1/1     Running     0               5m46s
kube-system       kube-scheduler-i-0033b408f7a1d55f3            1/1     Running     0               4m27s
kube-system       kube-scheduler-i-04d089ed896cfafe1            1/1     Running     1 (4m50s ago)   5m58s
kube-system       kube-scheduler-i-09b23242f40eabcca            1/1     Running     0               5m1s
longhorn-system   csi-attacher-6454556647-767p2                 1/1     Running     0               115s
longhorn-system   csi-attacher-6454556647-hz8lj                 1/1     Running     0               115s
longhorn-system   csi-attacher-6454556647-z5ftg                 1/1     Running     0               115s
longhorn-system   csi-provisioner-869bdc4b79-2v4wx              1/1     Running     0               115s
longhorn-system   csi-provisioner-869bdc4b79-4xcv4              1/1     Running     0               114s
longhorn-system   csi-provisioner-869bdc4b79-9q95d              1/1     Running     0               114s
longhorn-system   csi-resizer-6d8cf5f99f-dwdrq                  1/1     Running     0               114s
longhorn-system   csi-resizer-6d8cf5f99f-klvcr                  1/1     Running     0               114s
longhorn-system   csi-resizer-6d8cf5f99f-ptpzb                  1/1     Running     0               114s
longhorn-system   csi-snapshotter-588457fcdf-dlkdq              1/1     Running     0               113s
longhorn-system   csi-snapshotter-588457fcdf-p2c7c              1/1     Running     0               113s
longhorn-system   csi-snapshotter-588457fcdf-p5smn              1/1     Running     0               113s
longhorn-system   engine-image-ei-fa2dfbf0-bkwhx                1/1     Running     0               2m7s
longhorn-system   engine-image-ei-fa2dfbf0-cqq9n                1/1     Running     0               2m8s
longhorn-system   engine-image-ei-fa2dfbf0-lhjjc                1/1     Running     0               2m7s
longhorn-system   instance-manager-e-542b1382                   1/1     Running     0               119s
longhorn-system   instance-manager-e-a5e124bb                   1/1     Running     0               2m4s
longhorn-system   instance-manager-e-acb2a517                   1/1     Running     0               2m7s
longhorn-system   instance-manager-r-11ab6af6                   1/1     Running     0               119s
longhorn-system   instance-manager-r-5b82fba2                   1/1     Running     0               2m4s
longhorn-system   instance-manager-r-c2561fa0                   1/1     Running     0               2m6s
longhorn-system   longhorn-csi-plugin-4br28                     2/2     Running     0               113s
longhorn-system   longhorn-csi-plugin-8gdxf                     2/2     Running     0               113s
longhorn-system   longhorn-csi-plugin-wc6tt                     2/2     Running     0               113s
longhorn-system   longhorn-driver-deployer-7dddcdd5bb-zjh4k     1/1     Running     0               2m31s
longhorn-system   longhorn-manager-cbsh7                        1/1     Running     0               2m31s
longhorn-system   longhorn-manager-d2t75                        1/1     Running     1 (2m9s ago)    2m31s
longhorn-system   longhorn-manager-xqlfv                        1/1     Running     1 (2m9s ago)    2m31s
longhorn-system   longhorn-ui-7648d6cd69-tc6b9                  1/1     Running     0               2m31s
```

#### Public LB check

We can now test the public load balancer, nginx ingress controller and the security group ingress rules. On your local PC run:

```
curl -k -v https://k8s-ext-<REDACTED>.elb.amazonaws.com/
*   Trying 34.x.x.x:443...
* TCP_NODELAY set
* Connected to k8s-ext-<REDACTED>.elb.amazonaws.com (34.x.x.x) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* ALPN, server accepted to use h2
* Server certificate:
*  subject: C=IT; ST=Italy; L=Brescia; O=GL Ltd; OU=IT; CN=testlb.domainexample.com; emailAddress=email@you.com
*  start date: Apr 11 08:20:12 2022 GMT
*  expire date: Apr 11 08:20:12 2023 GMT
*  issuer: C=IT; ST=Italy; L=Brescia; O=GL Ltd; OU=IT; CN=testlb.domainexample.com; emailAddress=email@you.com
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x55c6560cde10)
> GET / HTTP/2
> Host: k8s-ext-<REDACTED>.elb.amazonaws.com
> user-agent: curl/7.68.0
> accept: */*
> 
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 404 
< date: Tue, 12 Apr 2022 10:08:18 GMT
< content-type: text/html
< content-length: 146
< strict-transport-security: max-age=15724800; includeSubDomains
< 
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host k8s-ext-<REDACTED>.elb.amazonaws.com left intact
```

*404* is a correct response since the cluster is empty.

## Deploy a sample stack

We use the same stack used in [this](https://github.com/garutilorenzo/k3s-oci-cluster) repository.
This stack **need** longhorn and nginx ingress.

To test all the components of the cluster we can deploy a sample stack. The stack is composed by the following components:

* MariaDB
* Nginx
* Wordpress

Each component is made by: one deployment and one service.
Wordpress and nginx share the same persistent volume (ReadWriteMany with longhorn storage class). The nginx configuration is stored in four ConfigMaps and  the nginx service is exposed by the nginx ingress controller.

Deploy the resources with:

```
kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/mariadb/all-resources.yml
kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/nginx/all-resources.yml
kubectl apply -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/wordpress/all-resources.yml
```

**NOTE** to install WP and reach the *wp-admin* path you have to edit the nginx deployment and change this line:

```yaml
 env:
  - name: SECURE_SUBNET
    value: 8.8.8.8/32 # change-me
```

and set your public ip address.

To check the status:

```
root@i-04d089ed896cfafe1:~# kubectl get pods -o wide
NAME                         READY   STATUS    RESTARTS   AGE     IP            NODE                  NOMINATED NODE   READINESS GATES
mariadb-6cbf998bd6-s98nh     1/1     Running   0          2m21s   10.244.2.13   i-072bf7de2e94e6f2d   <none>           <none>
nginx-68b4dfbcb6-s6zfh       1/1     Running   0          19s     10.244.1.12   i-0121c2149821379cc   <none>           <none>
wordpress-558948b576-jgvm2   1/1     Running   0          71s     10.244.3.14   i-0cb1e2e7784768b22   <none>           <none>

root@i-04d089ed896cfafe1:~# kubectl get deployments
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
mariadb     1/1     1            1           2m32s
nginx       1/1     1            1           30s
wordpress   1/1     1            1           82s

root@i-04d089ed896cfafe1:~# kubectl get svc
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes      ClusterIP   10.96.0.1       <none>        443/TCP    14m
mariadb-svc     ClusterIP   10.108.78.60    <none>        3306/TCP   2m43s
nginx-svc       ClusterIP   10.103.145.57   <none>        80/TCP     41s
wordpress-svc   ClusterIP   10.103.49.246   <none>        9000/TCP   93s
```

Now you are ready to setup WP, open the LB public ip and follow the wizard. **NOTE** nginx and the Kubernetes Ingress rule are configured without virthual host/server name.

![k8s wp install](https://garutilorenzo.github.io/images/k8s-wp.png?)

To clean the deployed resources:

```
kubectl delete -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/mariadb/all-resources.yml
kubectl delete -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/nginx/all-resources.yml
kubectl delete -f https://raw.githubusercontent.com/garutilorenzo/k3s-oci-cluster/master/deployments/wordpress/all-resources.yml
```

## Clean up

Before destroy all the infrastructure **DELETE** all the object in the S3 bucket.

```
terraform destroy
```

## TODO

* Extend the IAM role for the cluster autoscaler
* Install the node termination handler for the EC2 spot instances
* Auto update the certificate/token on the S3 bucket, at the moment the certificate i generated only once.
