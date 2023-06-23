locals {
  private_subnet_ids   = [for k, v in aws_subnet.private : v.id]
  private_subnet_cidrs = [for k, v in aws_subnet.private : v.cidr_block]

  number_of_broker_nodes = length(local.private_subnet_ids)

  /*
  The output bootstrap_brokers_tls is a SINGLE string containing the DNS names (or IP addresses) and TLS port pairs of the MSK brokers.
  Each broker domain starts with 'b-X.' were X is the number of the broker in the cluster. 
  The bootstrap_brokers_tls string is split into a map in the format { b-X: PORT}.
  */
  broker_port_map = { for v in split(",", aws_msk_cluster.this.bootstrap_brokers_tls) : split(".", v)[0] => split(":", v)[1] }

  /*
  As we are not using custom ports for the brokers, the port will always the same (9094). 
  Therefore, we can extract the port by using the first map element.
  */
  broker_port = distinct(values(local.broker_port_map))[0]

  /*
  The broker_info_map contains the information needed for the VPC Endpoint Services.
  As the values in data.aws_msk_broker_nodes.this.node_info_list cannot be determined until the Terraform configuration has been applied, we CANNOT use this map as the input for the module "vpc_endpoint_service".

  To be able to dynamically create out VPC Endpoint Services, we will create a second map 'endpoint_service_key_map' with an know
  number of map entries. The keys of the map will be equal to the key of the map 'broker_info_map' and will serve as the input
  for the module "vpc_endpoint_service".
  */
  broker_info_map = {
    for v in data.aws_msk_broker_nodes.this.node_info_list : "b-${v.broker_id}" => {
      eni_ip       = v.client_vpc_ip_address,
      endpoint_url = tolist(v.endpoints)[0]
      port         = local.broker_port_map["b-${v.broker_id}"]
    }
  }

  endpoint_service_key_map = { for n in range(1, local.number_of_broker_nodes + 1) : "b-${n}" => true }

  /*
  The Kafka Consumer Account will need information regarding the cluster. The map 'kafka_cluster_map' contains all the
  necessary information and will be shared via a Secrets Manager secret.
  */
  kafka_cluster_map = {
    for k, v in local.broker_info_map : k => {
      endpoint_url = v.endpoint_url,
      broker_port  = v.port,
      service_name = module.vpc_endpoint_service[k].service_name
    }
  }
}
