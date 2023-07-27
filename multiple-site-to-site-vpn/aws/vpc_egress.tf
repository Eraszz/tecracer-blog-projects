################################################################################
# VPC
################################################################################

resource "aws_vpc" "egress" {
  cidr_block           = var.vpc_cidr_block_egress
  enable_dns_hostnames = true

  tags = {
    Name = format("egress-%s", var.application_name)
  }
}


################################################################################
# Public Subnets
################################################################################

resource "aws_subnet" "public_egress" {
  for_each = local.public_subnets_egress

  vpc_id = aws_vpc.egress.id

  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = format("public-egress-%s-%s", var.application_name, each.value.availability_zone)
  }
}


################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "egress" {
  vpc_id = aws_vpc.egress.id
}


################################################################################
# Public Route table
################################################################################

resource "aws_route_table" "public_egress" {
  vpc_id = aws_vpc.egress.id

  tags = {
    Name = format("public-egress-%s", var.application_name)
  }
}

resource "aws_route" "public_tgw" {

  route_table_id         = aws_route_table.public_egress.id
  destination_cidr_block = aws_vpc.client.cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.this.id

}

resource "aws_route" "public_egress" {

  route_table_id         = aws_route_table.public_egress.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.egress.id

}



################################################################################
# Public Route Association
################################################################################

resource "aws_route_table_association" "public_egress" {
  for_each = aws_subnet.public_egress

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_egress.id
}


################################################################################
# Private subnets
################################################################################

resource "aws_subnet" "private_egress" {
  for_each = local.private_subnets_egress

  vpc_id = aws_vpc.egress.id

  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = format("private-egress-%s-%s", var.application_name, each.value.availability_zone)
  }
}


################################################################################
# EIP for NAT Gateway
################################################################################

resource "aws_eip" "egress" {
  for_each = aws_subnet.private_egress
  domain   = "vpc"
}


################################################################################
# NAT Gateway
################################################################################

resource "aws_nat_gateway" "egress" {
  for_each = aws_subnet.private_egress

  subnet_id     = aws_subnet.public_egress[each.key].id
  allocation_id = aws_eip.egress[each.key].id

  tags = {
    Name = format("private-egress-%s-%s", var.application_name, each.value.availability_zone)
  }
}


################################################################################
# Private route tables
################################################################################

resource "aws_route_table" "private_egress" {
  for_each = aws_subnet.private_egress

  vpc_id = aws_vpc.egress.id

  tags = {
    Name = format("private-egress-%s-%s", var.application_name, each.value.availability_zone)
  }
}


resource "aws_route" "private_egress" {
  for_each = aws_subnet.private_egress

  route_table_id         = aws_route_table.private_egress[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.egress[each.key].id
}


################################################################################
# Private route associations
################################################################################

resource "aws_route_table_association" "private_egress" {
  for_each = aws_subnet.private_egress

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_egress[each.key].id
}
