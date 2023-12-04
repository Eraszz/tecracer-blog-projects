################################################################################
# Route53 hosted zone
################################################################################

resource "aws_route53_zone" "this" {
  name = "kafka.${data.aws_region.current.name}.amazonaws.com"

  vpc {
    vpc_id     = aws_vpc.this.id
    vpc_region = data.aws_region.current.name
  }
}


################################################################################
# Route53 records
################################################################################

resource "aws_route53_record" "this" {
  for_each = aws_vpc_endpoint.this

  zone_id = aws_route53_zone.this.id
  name    = var.kafka_cluster_information_map[each.key].endpoint_url
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = each.value.dns_entry[0].dns_name
    zone_id                = each.value.dns_entry[0].hosted_zone_id
  }
}