locals {

  firewall_endpoints = flatten([
    for key, value in module.inspection.private_subnet_map : [{
      vpc_endpoint_id        = tolist(aws_networkfirewall_firewall.this.firewall_status[0].sync_states)[index(keys(module.inspection.private_subnet_map), key)].attachment[0].endpoint_id
      availability_zone      = value.availability_zone
      destination_cidr_block = "0.0.0.0/0"
      }
    ]
  ])

  /*
  firewall_endpoints = [for value in aws_networkfirewall_firewall.this.firewall_status[0].sync_states : {
    vpc_endpoint_id        = value.attachment[0].endpoint_id
    availability_zone      = value.availability_zone
    destination_cidr_block = "0.0.0.0/0"
  }]
  */


  nlb_private_ipv4_addresses      = { for value in aws_lb.workload.subnet_mapping : value.subnet_id => value.private_ipv4_address }
  nlb_private_ipv4_addresses_list = [for value in aws_lb.workload.subnet_mapping : value.private_ipv4_address]

  transit_gateway_vpc_attachments = {
    egress = {
      subnet_ids = module.egress.tgw_subnet_id_list
      vpc_id     = module.egress.id
    },
    ingress = {
      subnet_ids = module.ingress.tgw_subnet_id_list
      vpc_id     = module.ingress.id
    },
    workload = {
      subnet_ids = module.workload.tgw_subnet_id_list
      vpc_id     = module.workload.id
    },
    inspection = {
      subnet_ids             = module.inspection.tgw_subnet_id_list
      vpc_id                 = module.inspection.id
      appliance_mode_support = "enable"
    }
  }

  transit_gateway_route_table_associations = {
    ingress  = aws_ec2_transit_gateway_vpc_attachment.this["ingress"].id,
    workload = aws_ec2_transit_gateway_vpc_attachment.this["workload"].id,
    vpn      = aws_vpn_connection.this.transit_gateway_attachment_id
  }

  transit_gateway_route_table_propagations = {
    egress   = aws_ec2_transit_gateway_vpc_attachment.this["egress"].id,
    ingress  = aws_ec2_transit_gateway_vpc_attachment.this["ingress"].id,
    workload = aws_ec2_transit_gateway_vpc_attachment.this["workload"].id
  }
}
