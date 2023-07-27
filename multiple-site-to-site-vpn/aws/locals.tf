locals {

  public_subnets_client = { for index, v in var.availability_zones : "subnet_${index}" =>
    {
      cidr_block        = cidrsubnet(var.vpc_cidr_block_client, 8, index)
      availability_zone = v
    }
  }

  private_subnets_client = { for index, v in var.availability_zones : "subnet_${index}" =>
    {
      cidr_block        = cidrsubnet(var.vpc_cidr_block_client, 8, index + 128)
      availability_zone = v
    }
  }

  public_subnets_egress = { for index, v in var.availability_zones : "subnet_${index}" =>
    {
      cidr_block        = cidrsubnet(var.vpc_cidr_block_egress, 8, index)
      availability_zone = v
    }
  }

  private_subnets_egress = { for index, v in var.availability_zones : "subnet_${index}" =>
    {
      cidr_block        = cidrsubnet(var.vpc_cidr_block_egress, 8, index + 128)
      availability_zone = v
    }
  }

  private_subnet_ids_client = [for k, v in aws_subnet.private_client : v.id]
  private_subnet_ids_egress = [for k, v in aws_subnet.private_egress : v.id]

  vpn_output_map = { for key, value in aws_vpn_connection.this : key => {
    customer_gateway_peer_ip           = aws_customer_gateway.this[key].bgp_asn
    customer_gateway_asn               = aws_customer_gateway.this[key].ip_address
    tunnel1_address                    = value.tunnel1_address
    tunnel1_cgw_inside_address         = value.tunnel1_cgw_inside_address
    tunnel1_vgw_inside_address         = value.tunnel1_vgw_inside_address
    tunnel1_preshared_key              = value.tunnel1_preshared_key
    tunnel1_bgp_asn                    = value.tunnel1_bgp_asn
    tunnel2_address                    = value.tunnel2_address
    tunnel2_cgw_inside_address         = value.tunnel2_cgw_inside_address
    tunnel2_vgw_inside_address         = value.tunnel2_vgw_inside_address
    tunnel2_preshared_key              = value.tunnel2_preshared_key
    tunnel2_bgp_asn                    = value.tunnel2_bgp_asn
    customer_gateway_ipv4_network_cidr = value.local_ipv4_network_cidr
    aws_ipv4_network_cidr              = value.remote_ipv4_network_cidr
  } }
}