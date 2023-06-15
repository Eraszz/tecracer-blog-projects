################################################################################
# VPC Endpoint (DynamoDB)
################################################################################

resource "aws_vpc_endpoint" "this" {
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"

  vpc_id = aws_vpc.this.id
}

################################################################################
# VPC Endpoint Route Table Association for Gateway Type
################################################################################

resource "aws_vpc_endpoint_route_table_association" "this" {
  for_each = aws_route_table.private

  vpc_endpoint_id = aws_vpc_endpoint.this.id
  route_table_id  = each.value.id
}
