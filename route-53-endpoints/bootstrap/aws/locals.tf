locals {

  public_subnets = { for index, v in var.availability_zones : "subnet_${index}" =>
    {
      cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, index)
      availability_zone = v
    }
  }

  private_subnets = { for index, v in var.availability_zones : "subnet_${index}" =>
    {
      cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, index + 128)
      availability_zone = v
    }
  }

  private_subnet_ids   = [for k, v in aws_subnet.private : v.id]
  private_subnet_cidrs = [for k, v in aws_subnet.private : v.cidr_block]

  client_ip = cidrhost(local.private_subnet_cidrs[0], 10)

  vpn_output_map = {
    tunnel1_address                    = aws_vpn_connection.this.tunnel1_address
    tunnel1_cgw_inside_address         = aws_vpn_connection.this.tunnel1_cgw_inside_address
    tunnel1_vgw_inside_address         = aws_vpn_connection.this.tunnel1_vgw_inside_address
    tunnel1_preshared_key              = aws_vpn_connection.this.tunnel1_preshared_key
    tunnel2_address                    = aws_vpn_connection.this.tunnel2_address
    tunnel2_cgw_inside_address         = aws_vpn_connection.this.tunnel2_cgw_inside_address
    tunnel2_vgw_inside_address         = aws_vpn_connection.this.tunnel2_vgw_inside_address
    tunnel2_preshared_key              = aws_vpn_connection.this.tunnel2_preshared_key
    customer_gateway_ipv4_network_cidr = aws_vpn_connection.this.local_ipv4_network_cidr
    aws_ipv4_network_cidr              = aws_vpn_connection.this.remote_ipv4_network_cidr
    customer_gateway_asn               = aws_customer_gateway.this.bgp_asn
    customer_gateway_peer_ip           = aws_customer_gateway.this.ip_address
  }
}