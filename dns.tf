#Dns Configuration (Hosted Zone on Route53 must already exist and we can get it)
data "aws_route53_zone" "dns" {
  provider = aws.master-region
  name     = var.dns_name
}

#Create record in hosted zone for ACM Certificate Domain Verification
resource "aws_route53_record" "cert_validation" {
  provider = aws.master-region
  for_each = {
    for val in aws_acm_certificate.jenkins_lb_https.domain_validation_options : val.domain_name => {
      name   = val.resource_record_name
      record = val.resource_record_value
      type   = val.resource_record_type
    }
  }
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  zone_id = data.aws_route53_zone.dns.zone_id
  ttl     = 60
}

#Create alias record from Route53 towards ALB
resource "aws_route53_record" "jenkins" {
  provider = aws.master-region
  name     = join(".", ["jenkins", data.aws_route53_zone.dns.name])
  type     = "A"
  zone_id  = data.aws_route53_zone.dns.zone_id
  alias {
    evaluate_target_health = false
    name                   = aws_lb.application_lb.dns_name
    zone_id                = aws_lb.application_lb.zone_id
  }
}