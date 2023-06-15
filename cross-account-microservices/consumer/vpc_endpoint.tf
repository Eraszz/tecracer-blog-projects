################################################################################
# Get Current region
################################################################################

data "aws_region" "current" {}


################################################################################
# VPC Endpoint
################################################################################

resource "aws_vpc_endpoint" "this" {
  service_name      = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  vpc_endpoint_type = "Interface"

  vpc_id             = aws_vpc.this.id
  security_group_ids = [aws_security_group.vpc_endpoint.id]
  subnet_ids         = local.private_subnet_ids
}

################################################################################
# Endpoint Security Group
################################################################################

resource "aws_security_group" "vpc_endpoint" {
  name   = "${var.application_name}-vpc-endpoint"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "vpc_endpoint_ingress" {
  security_group_id = aws_security_group.vpc_endpoint.id

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}
