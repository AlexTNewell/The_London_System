resource "aws_acm_certificate" "Pepperoni_Certificate" {
  domain_name       = "thelondonchesssystem.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "primary" {
  name = "thelondonchesssystem.com"
}


resource "aws_route53_record" "validation_records" {
  depends_on      = [aws_acm_certificate.Pepperoni_Certificate, aws_route53_zone.primary]
  allow_overwrite = true
  zone_id = aws_route53_zone.primary.zone_id
  for_each = {
      for dvo in aws_acm_certificate.Pepperoni_Certificate.domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    }
  
    name            = each.value.name
    records         = [each.value.record]
    ttl             = 60
    type            = each.value.type

}

resource "aws_acm_certificate_validation" "Pepperoni_Certificate_Validation" {
  depends_on      = [aws_acm_certificate.Pepperoni_Certificate, aws_route53_zone.primary]
  certificate_arn = aws_acm_certificate.Pepperoni_Certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_records : record.fqdn]
}

resource "aws_route53_record" "www" {
  depends_on = [aws_acm_certificate_validation.Pepperoni_Certificate_Validation]
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.thelondonchesssystem.com"
  type    = "A"

  alias {
      name                   = aws_lb.app_alb.dns_name
      zone_id                = aws_lb.app_alb.zone_id
      evaluate_target_health = false
    }
}
