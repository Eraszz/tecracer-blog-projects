################################################################################
# TGW subnets
################################################################################

resource "aws_subnet" "tgw" {
  for_each = toset(var.tgw_subnets)

  vpc_id = aws_vpc.this.id

  cidr_block        = each.value
  availability_zone = var.availability_zones[index(var.tgw_subnets, each.value)]

  tags = {
    Name = format("tgw-%s-%s", var.name, var.availability_zones[index(var.tgw_subnets, each.value)])
  }
}

################################################################################
# TGW Route table
################################################################################

resource "aws_route_table" "tgw" {
  for_each = aws_subnet.tgw

  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("%s-tgw-%s", var.name, each.value.availability_zone),
    tier = "tgw"
  }
}

resource "aws_route" "tgw_nat" {
  for_each = var.create_nat_gateway ? aws_subnet.tgw : {}

  route_table_id         = aws_route_table.tgw[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[keys(aws_subnet.public)[index(keys(aws_subnet.tgw), each.key)]].id
}

resource "aws_route" "tgw_custom" {
  for_each = local.tgw_custom_routes_map

  route_table_id = aws_route_table.tgw[each.value.subnet_key].id

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

resource "aws_route" "tgw_custom_specific" {
  for_each = local.tgw_custom_routes_specific_map

  route_table_id = aws_route_table.tgw[each.value.subnet_key].id

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
# TGW Route Association
################################################################################

resource "aws_route_table_association" "tgw" {
  for_each = aws_subnet.tgw

  subnet_id      = each.value.id
  route_table_id = aws_route_table.tgw[each.key].id
}