################################################################################
# VPC Endpoint Service
################################################################################

resource "aws_vpc_endpoint_service" "this" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.this.arn]
}


################################################################################
# VPC Endpoint Service allowed principals
################################################################################

resource "aws_vpc_endpoint_service_allowed_principal" "this" {
  for_each = toset(var.allowed_service_principal_arns)

  vpc_endpoint_service_id = aws_vpc_endpoint_service.this.id
  principal_arn           = each.value
}