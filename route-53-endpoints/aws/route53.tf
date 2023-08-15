locals {
  dns_server_ip_cidr_notation = format("%s/32", var.on_premises_network.dns_server_ip)
}

################################################################################
# Private Hosted Zone
################################################################################

resource "aws_route53_zone" "this" {
  name = format("%s.com", var.application_name)

  vpc {
    vpc_id = data.aws_vpc.this.id
  }
}


################################################################################
# Record
################################################################################

resource "aws_route53_record" "this" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "client"
  type    = "A"
  ttl     = 300
  records = [var.aws_site_client_ip]
}


################################################################################
# Inbound Endpoint
################################################################################

resource "aws_route53_resolver_endpoint" "inbound" {
  name      = "${var.application_name}-inbound"
  direction = "INBOUND"

  security_group_ids = [aws_security_group.inbound.id]

  dynamic "ip_address" {
    for_each = data.aws_subnets.private.ids
    content {
      subnet_id = ip_address.value
    }
  }
}

data "aws_route53_resolver_endpoint" "inbound" {
  resolver_endpoint_id = aws_route53_resolver_endpoint.inbound.id
}


################################################################################
# Outbound Endpoint
################################################################################

resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "${var.application_name}-outbound"
  direction = "OUTBOUND"

  security_group_ids = [aws_security_group.outbound.id]

  dynamic "ip_address" {
    for_each = data.aws_subnets.private.ids
    content {
      subnet_id = ip_address.value
    }
  }
}

resource "aws_route53_resolver_rule" "this" {
  domain_name          = var.on_premises_network.domain_name
  name                 = "outbound"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  target_ip {
    ip = var.on_premises_network.dns_server_ip
  }
}

resource "aws_route53_resolver_rule_association" "this" {
  resolver_rule_id = aws_route53_resolver_rule.this.id
  vpc_id           = data.aws_vpc.this.id
}


################################################################################
# Inbound Endpoint Security Group
################################################################################

resource "aws_security_group" "inbound" {
  name   = "${var.application_name}-inbound-endpoint"
  vpc_id = data.aws_vpc.this.id
}

resource "aws_security_group_rule" "inbound_egress" {
  security_group_id = aws_security_group.inbound.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = [data.aws_vpc.this.cidr_block]
}


resource "aws_security_group_rule" "inbound_udp_ingress" {
  security_group_id = aws_security_group.inbound.id

  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  cidr_blocks = [local.dns_server_ip_cidr_notation]
}

resource "aws_security_group_rule" "inbound_tcp_ingress" {
  security_group_id = aws_security_group.inbound.id

  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  cidr_blocks = [local.dns_server_ip_cidr_notation]
}


################################################################################
# Outbound Endpoint Security Group
################################################################################

resource "aws_security_group" "outbound" {
  name   = "${var.application_name}-outbound-endpoint"
  vpc_id = data.aws_vpc.this.id
}

resource "aws_security_group_rule" "outbound_udp_egress" {
  security_group_id = aws_security_group.outbound.id

  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  cidr_blocks = [local.dns_server_ip_cidr_notation]
}

resource "aws_security_group_rule" "outbound_tcp_egress" {
  security_group_id = aws_security_group.outbound.id

  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  cidr_blocks = [local.dns_server_ip_cidr_notation]
}

resource "aws_security_group_rule" "outbound_ingress" {
  security_group_id = aws_security_group.outbound.id

  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = [data.aws_vpc.this.cidr_block]
}

