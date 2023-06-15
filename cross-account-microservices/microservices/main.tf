module "microservice" {
  for_each = var.microservices

  source = "../modules/microservice"

  vpc_cidr_block  = var.vpc_cidr_block
  private_subnets = var.private_subnets

  api_gateway_definition_template = "${path.module}/templates/api-gateway-definition-template.yaml"
  application_name                = var.application_name
  microservice_name               = each.key
  microservice_order_options      = each.value
  domain_name                     = format("%s.%s.com", each.key, var.application_name)
}
