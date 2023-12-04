################################################################################
# Private subnets
################################################################################

resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)

  vpc_id = aws_vpc.this.id

  cidr_block        = each.value
  availability_zone = var.availability_zones[index(var.private_subnets, each.value)]

  tags = {
    Name = format("private-%s-%s", var.name, var.availability_zones[index(var.private_subnets, each.value)])
  }
}

################################################################################
# NAT Gateway
################################################################################

resource "aws_eip" "this" {
  for_each = var.create_nat_gateway ? aws_subnet.public : {}
  domain   = "vpc"

  tags = {
    Name = format("%s-nat-gateway-%s", var.name, each.value.availability_zone),
  }
}

resource "aws_nat_gateway" "this" {
  for_each = var.create_nat_gateway ? aws_eip.this : {}

  subnet_id     = aws_subnet.public[each.key].id
  allocation_id = each.value.id

  tags = {
    Name = format("%s-nat-gateway-%s", var.name, aws_subnet.public[each.key].availability_zone),
  }
}

################################################################################
# Private Route table
################################################################################

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("%s-private-%s", var.name, each.value.availability_zone),
    tier = "private"
  }
}

resource "aws_route" "private_nat" {
  for_each = var.create_nat_gateway ? aws_subnet.private : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[keys(aws_subnet.public)[index(keys(aws_subnet.private), each.key)]].id
}

resource "aws_route" "private_custom" {
  for_each = local.private_custom_routes_map

  route_table_id = aws_route_table.private[each.value.subnet_key].id

  destination_cidr_block      = lookup(each.value, "destination_cidr_block", null)
  destination_ipv6_cidr_block = lookup(each.value, "destination_ipv6_cidr_block", null)
  destination_prefix_list_id  = lookup(each.value, "destination_prefix_list_id", null)
  carrier_gateway_id          = lookup(each.value, "carrier_gateway_id", null)
  core_network_arn            = lookup(each.value, "core_network_arn", null)
  egress_only_gateway_id      = lookup(each.value, "egress_only_gateway_id", null)
  gateway_id                  = lookup(each.value, "gateway_id", null)
  nat_gateway_id              = lookup(each.value, "nat_gateway_id", null)
  local_gateway_id            = lookup(each.value, "local_gateway_id", null)
  network_interface_id        = lookup(each.value, "network_interface_id", null)
  transit_gateway_id          = lookup(each.value, "transit_gateway_id", null)
  vpc_endpoint_id             = lookup(each.value, "vpc_endpoint_id", null)
  vpc_peering_connection_id   = lookup(each.value, "vpc_peering_connection_id", null)
}

################################################################################
# Private Route Association
################################################################################

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}