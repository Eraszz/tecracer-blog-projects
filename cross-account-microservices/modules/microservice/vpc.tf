################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = format("private-%s-%s", var.application_name, var.microservice_name)
  }
}


################################################################################
# Private subnets
################################################################################

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id = aws_vpc.this.id

  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = format("private-%s-%s-%s", var.application_name, var.microservice_name, each.value.availability_zone)
  }
}


################################################################################
# Private route tables
################################################################################

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("private-%s-%s-%s", var.application_name, var.microservice_name, each.value.availability_zone)
  }
}


################################################################################
# Private route associations
################################################################################

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
