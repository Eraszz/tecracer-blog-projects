################################################################################
# Route53 hosted zone
################################################################################

resource "aws_route53_zone" "this" {
  name = "${var.application_name}.com"

  vpc {
    vpc_id     = aws_vpc.this.id
    vpc_region = data.aws_region.current.name
  }
}


################################################################################
# ALB Alias record
################################################################################

resource "aws_route53_record" "this" {
  for_each = var.microservices

  zone_id = aws_route53_zone.this.id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
