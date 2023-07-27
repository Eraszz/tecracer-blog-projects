################################################################################
# Transit Gateway
################################################################################

resource "aws_ec2_transit_gateway" "this" {
  amazon_side_asn  = "64512"
  vpn_ecmp_support = "enable"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "client" {
  subnet_ids         = local.private_subnet_ids_client
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = aws_vpc.client.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "egress" {
  subnet_ids         = local.private_subnet_ids_egress
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = aws_vpc.egress.id
}


################################################################################
# Site-to-Site VPN connections
################################################################################

resource "aws_customer_gateway" "this" {
  for_each = var.on_premises_networks

  bgp_asn    = each.value.bgp_asn
  ip_address = each.value.customer_gateway_ip
  type       = "ipsec.1"

  tags = {
    Name = each.key
  }
}

resource "aws_vpn_connection" "this" {
  for_each = aws_customer_gateway.this

  customer_gateway_id = each.value.id
  transit_gateway_id  = aws_ec2_transit_gateway.this.id
  type                = each.value.type
  enable_acceleration = true

  local_ipv4_network_cidr  = var.on_premises_networks[each.key].cidr_range
  remote_ipv4_network_cidr = var.vpc_cidr_block_client
}


################################################################################
# Default Route
################################################################################

resource "aws_ec2_transit_gateway_route" "this" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.this.association_default_route_table_id
}
