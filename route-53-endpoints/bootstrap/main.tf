module "aws_site" {
  source = "./aws"

  application_name = "aws-site"

  vpc_cidr_block     = var.aws_cidr_block
  availability_zones = var.availability_zones

  on_premises_network = {
    customer_gateway_ip = module.on_premises.peer_ip
    cidr_range          = var.on_premises_cidr_block
    bgp_asn             = 65001
  }
}

module "on_premises" {
  source = "./on-premises"

  application_name = "on-premises"

  vpc_cidr_block     = var.on_premises_cidr_block
  availability_zones = var.availability_zones

  aws_network = {
    cidr_range = var.aws_cidr_block
    peer_ips = [
      module.aws_site.vpn_output_map.tunnel1_address,
      module.aws_site.vpn_output_map.tunnel2_address
    ]
    preshared_keys = [
      module.aws_site.vpn_output_map.tunnel1_preshared_key,
      module.aws_site.vpn_output_map.tunnel2_preshared_key
    ]
    domain_name = "aws-site.com"
  }
}
