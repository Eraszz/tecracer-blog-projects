################################################################################
# VPC
################################################################################

resource "aws_vpc" "client" {
  cidr_block           = var.vpc_cidr_block_client
  enable_dns_hostnames = true

  tags = {
    Name = format("client-%s", var.application_name)
  }
}


################################################################################
# Private subnets
################################################################################

resource "aws_subnet" "private_client" {
  for_each = local.private_subnets_client

  vpc_id = aws_vpc.client.id

  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = format("private-client-%s-%s", var.application_name, each.value.availability_zone)
  }
}


################################################################################
# Private route tables
################################################################################

resource "aws_route_table" "private_client" {
  for_each = aws_subnet.private_client

  vpc_id = aws_vpc.client.id

  tags = {
    Name = format("private-client-%s-%s", var.application_name, each.value.availability_zone)
  }
}


resource "aws_route" "private_client" {
  for_each = aws_subnet.private_client

  route_table_id         = aws_route_table.private_client[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}


################################################################################
# Private route associations
################################################################################

resource "aws_route_table_association" "private_client" {
  for_each = aws_subnet.private_client

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_client[each.key].id
}
