################################################################################
# VPC Endpoint
################################################################################

resource "aws_vpc_endpoint" "this" {
  for_each = var.kafka_cluster_information_map

  service_name      = each.value.service_name
  vpc_endpoint_type = "Interface"

  vpc_id             = aws_vpc.this.id
  security_group_ids = [aws_security_group.this.id]
  subnet_ids         = local.private_subnet_ids
}

################################################################################
# Endpoint Security Group
################################################################################

resource "aws_security_group" "this" {
  name   = var.application_name
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "ingress" {
  for_each = local.broker_ports

  security_group_id = aws_security_group.this.id

  type        = "ingress"
  from_port   = each.value
  to_port     = each.value
  protocol    = "tcp"
  cidr_blocks = local.private_subnet_cidrs
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.this.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}