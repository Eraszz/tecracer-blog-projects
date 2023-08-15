################################################################################
# VPN Gateway
################################################################################

resource "aws_vpn_gateway" "this" {
  vpc_id          = aws_vpc.this.id
  amazon_side_asn = "64512"
}

resource "aws_customer_gateway" "this" {
  bgp_asn    = var.on_premises_network.bgp_asn
  ip_address = var.on_premises_network.customer_gateway_ip
  type       = "ipsec.1"

  tags = {
    Name = "on-premises"
  }
}


################################################################################
# Site-to-Site VPN connections
################################################################################

resource "aws_vpn_connection" "this" {
  customer_gateway_id      = aws_customer_gateway.this.id
  vpn_gateway_id           = aws_vpn_gateway.this.id
  type                     = "ipsec.1"
  local_ipv4_network_cidr  = var.on_premises_network.cidr_range
  remote_ipv4_network_cidr = var.vpc_cidr_block

  static_routes_only = true
}

resource "aws_vpn_connection_route" "this" {
  destination_cidr_block = var.on_premises_network.cidr_range
  vpn_connection_id      = aws_vpn_connection.this.id
}
