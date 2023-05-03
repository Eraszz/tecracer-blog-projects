locals {
  private_subnet_ids   = [for k, v in aws_subnet.private : v.id]
  private_subnet_cidrs = [for key, v in aws_subnet.private : v.cidr_block]

  number_of_broker_nodes = length(local.private_subnet_ids)

  broker_port_map = { for v in split(",", aws_msk_cluster.this.bootstrap_brokers_tls) : split(".", v)[0] => split(":", v)[1] }
  broker_port     = distinct(values(local.broker_port_map))[0]

  subnet_map = { for key, v in aws_subnet.private : v.id => {
    cidr_block        = v.cidr_block,
    availability_zone = v.availability_zone
    }
  }

  broker_info_map = {
    for v in data.aws_msk_broker_nodes.this.node_info_list : "b-${v.broker_id}" => {
      broker_id    = v.broker_id,
      msk_node_arn = v.node_arn,
      subnet_id    = v.client_subnet,
      subnet_cidr  = local.subnet_map[v.client_subnet].cidr_block
      subnet_az    = local.subnet_map[v.client_subnet].availability_zone
      eni_id       = v.attached_eni_id,
      eni_ip       = v.client_vpc_ip_address,
      endpoint_url = tolist(v.endpoints)[0]
      port         = local.broker_port_map["b-${v.broker_id}"]
    }
  }

  endpoint_service_key_map = { for n in range(1, length(local.private_subnet_ids) + 1) : "b-${n}" => true }

  kafka_cluster_map = {
    for key, v in local.broker_info_map : key => {
      endpoint_url = v.endpoint_url,
      broker_port  = local.broker_port,
      service_name = module.vpc_endpoint_service[key].service_name,
      broker_az    = v.subnet_az
    }
  }
}
