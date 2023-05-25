## Module ACM Certificate 
# Description : This terraform module is used for requesting or importing SSL/TLS certificate.

resource "aws_acm_certificate" "import_certificate" {  
  count             = var.create_certificate ? 1 : 0
  private_key       = var.private_key
  certificate_body  = var.certificate_body
  certificate_chain = var.certificate_chain
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}
