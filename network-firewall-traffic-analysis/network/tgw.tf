################################################################################
# Transit Gateway
################################################################################

resource "aws_ec2_transit_gateway" "this" {
  amazon_side_asn  = "64512"
  vpn_ecmp_support = "enable"

  default_route_table_association = "disable"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = local.transit_gateway_vpc_attachments

  subnet_ids             = each.value.subnet_ids
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
  vpc_id                 = each.value.vpc_id
  appliance_mode_support = lookup(each.value, "appliance_mode_support", null)

  transit_gateway_default_route_table_association = false
}

################################################################################
# Site-to-Site VPN connections
################################################################################

resource "aws_customer_gateway" "this" {
  bgp_asn    = 65001
  ip_address = module.vpn.vpn_peer_ip
  type       = "ipsec.1"

  tags = {
    Name = var.application_name
  }
}

resource "aws_vpn_connection" "this" {
  customer_gateway_id = aws_customer_gateway.this.id
  transit_gateway_id  = aws_ec2_transit_gateway.this.id
  type                = "ipsec.1"

  static_routes_only = true

  local_ipv4_network_cidr  = var.on_premises_cidr_range
  remote_ipv4_network_cidr = var.aws_cidr_range
}


################################################################################
# Inspection Route Table
################################################################################

resource "aws_ec2_transit_gateway_route_table" "inspection" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = { Name = "inspection-route-table" }
}

resource "aws_ec2_transit_gateway_route" "egress" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["egress"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
}

resource "aws_ec2_transit_gateway_route" "vpn" {
  destination_cidr_block         = "172.31.0.0/16"
  transit_gateway_attachment_id  = aws_vpn_connection.this.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
}

resource "aws_ec2_transit_gateway_route_table_association" "inspection" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["inspection"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "inspection" {
  for_each = local.transit_gateway_route_table_propagations

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
}

################################################################################
# Spoke Route Table
################################################################################

resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = { Name = "spoke-route-table" }
}

resource "aws_ec2_transit_gateway_route" "spoke" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["inspection"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke" {
  for_each = local.transit_gateway_route_table_associations

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}


################################################################################
# Egress Route Table
################################################################################

resource "aws_ec2_transit_gateway_route_table" "egress" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = { Name = "egress-route-table" }
}

resource "aws_ec2_transit_gateway_route" "egress_default" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["egress"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

resource "aws_ec2_transit_gateway_route" "vpn_default" {
  destination_cidr_block         = "172.31.0.0/16"
  transit_gateway_attachment_id  = aws_vpn_connection.this.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

resource "aws_ec2_transit_gateway_route" "aws_default" {
  destination_cidr_block         = "10.0.0.0/8"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["inspection"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

resource "aws_ec2_transit_gateway_route_table_association" "egress" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this["egress"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}
