################################################################################
# Public Subnets
################################################################################

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)

  vpc_id = aws_vpc.this.id

  cidr_block              = each.value
  availability_zone       = var.availability_zones[index(var.public_subnets, each.value)]
  map_public_ip_on_launch = true

  tags = {
    Name = format("public-%s-%s", var.name, var.availability_zones[index(var.public_subnets, each.value)])
  }
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count = local.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.name
  }
}

################################################################################
# Public Route table
################################################################################

resource "aws_route_table" "public" {
  count = local.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = {
    Name = format("%s-public", var.name),
    tier = "public"
  }
}

resource "aws_route" "public_igw" {
  count = local.create_public_subnets ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route" "public_custom" {
  count = local.create_public_custom_routes && local.create_public_subnets ? length(var.public_custom_routes) : 0

  route_table_id = aws_route_table.public[0].id

  destination_cidr_block      = lookup(var.public_custom_routes[count.index], "destination_cidr_block", null)
  destination_ipv6_cidr_block = lookup(var.public_custom_routes[count.index], "destination_ipv6_cidr_block", null)
  destination_prefix_list_id  = lookup(var.public_custom_routes[count.index], "destination_prefix_list_id", null)
  carrier_gateway_id          = lookup(var.public_custom_routes[count.index], "carrier_gateway_id", null)
  core_network_arn            = lookup(var.public_custom_routes[count.index], "core_network_arn", null)
  egress_only_gateway_id      = lookup(var.public_custom_routes[count.index], "egress_only_gateway_id", null)
  gateway_id                  = lookup(var.public_custom_routes[count.index], "gateway_id", null)
  nat_gateway_id              = lookup(var.public_custom_routes[count.index], "nat_gateway_id", null)
  local_gateway_id            = lookup(var.public_custom_routes[count.index], "local_gateway_id", null)
  network_interface_id        = lookup(var.public_custom_routes[count.index], "network_interface_id", null)
  transit_gateway_id          = lookup(var.public_custom_routes[count.index], "transit_gateway_id", null)
  vpc_endpoint_id             = lookup(var.public_custom_routes[count.index], "vpc_endpoint_id", null)
  vpc_peering_connection_id   = lookup(var.public_custom_routes[count.index], "vpc_peering_connection_id", null)
}

################################################################################
# Public Route Association
################################################################################

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}
