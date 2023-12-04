locals {
  vpn_wan_ip        = cidrhost(data.aws_subnet.public.cidr_block, 30)
  vpn_lan_ip        = cidrhost(data.aws_subnet.private.cidr_block, 30)
  aws_peer_ips_cidr = formatlist("%s/32", var.aws_network.peer_ips)
}