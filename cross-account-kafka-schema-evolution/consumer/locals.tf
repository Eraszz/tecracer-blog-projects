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

  public_subnet_ids   = [for k, v in aws_subnet.public : v.id]
  public_subnet_cidrs = [for k, v in aws_subnet.public : v.cidr_block]

  private_subnet_ids   = [for k, v in aws_subnet.private : v.id]
  private_subnet_cidrs = [for k, v in aws_subnet.private : v.cidr_block]


  broker_ports          = [for k, v in var.kafka_cluster_information_map : v.broker_port]
  broker_port           = local.broker_ports[0]
  bootstrap_brokers_tls = join(",", [for k, v in var.kafka_cluster_information_map : "${v.endpoint_url}:${v.broker_port}"])


  event_source_mapping_subnet_list = [for v in local.private_subnet_ids : {
    "type" : "VPC_SUBNET",
    "uri" : "subnet:${v}"
    }
  ]

  event_source_mapping_security_group_list = [{
    "type" : "VPC_SECURITY_GROUP",
    "uri" : "security_group:${aws_security_group.this.id}"
    }
  ]
}