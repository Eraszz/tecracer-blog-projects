################################################################################
# NLB
################################################################################

module "vpc_endpoint_service" {
  for_each = local.endpoint_service_key_map

  source = "./modules/vpc-endpoint-service"

  name                           = each.key
  subnets                        = local.private_subnet_ids
  vpc_id                         = aws_vpc.this.id
  port                           = local.broker_info_map[each.key].port
  target_id                      = local.broker_info_map[each.key].eni_ip
  allowed_service_principal_arns = var.allowed_service_principal_arns
}
