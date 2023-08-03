module "on_premises_network" {
  for_each = var.on_premises_networks

  source = "../modules/on-prem-bootstrap"

  application_name                = each.key
  vpc_cidr_block                  = each.value.vpc_cidr_block
  aws_cidr_range                  = var.aws_cidr_range
  opposite_on_premises_cidr_range = each.value.opposite_on_premises_cidr_range
  aws_peer_ips                    = each.value.aws_peer_ips
  on_premises_peer_ip             = each.value.on_premises_peer_ip

}
