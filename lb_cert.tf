resource "aws_acm_certificate" "cert" {
  count            = var.install_nginx_ingress ? 1 : 0
  private_key      = file(var.PATH_TO_PUBLIC_LB_KEY)
  certificate_body = file(var.PATH_TO_PUBLIC_LB_CERT)
}