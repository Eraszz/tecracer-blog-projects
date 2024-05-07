locals {
  gwlb_endpoint_object     = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.this.secret_string))
}

################################################################################
# VPC Endpoint Service
################################################################################

resource "aws_vpc_endpoint" "this" {
  for_each = aws_subnet.gwlb

  vpc_id            = aws_vpc.this.id
  subnet_ids        = [each.value.id]
  
  service_name      = local.gwlb_endpoint_object.service_name
  vpc_endpoint_type = local.gwlb_endpoint_object.service_type
}
