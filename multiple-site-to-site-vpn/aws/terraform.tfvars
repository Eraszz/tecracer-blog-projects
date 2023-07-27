vpc_cidr_block_client = "172.16.0.0/16"
vpc_cidr_block_egress = "172.17.0.0/16"

application_name = "aws-site"

on_premises_networks = {
  on-premises-1 = {
    customer_gateway_ip = "xxxxxxxxxx"
    cidr_range          = "10.0.0.0/16"
    bgp_asn             = 65001
  }

  on-premises-2 = {
    customer_gateway_ip = "xxxxxxxxxx"
    cidr_range          = "10.1.0.0/16"
    bgp_asn             = 65002
  }
}

