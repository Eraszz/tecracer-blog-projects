locals {
  private_subnet_ids   = [for k, v in aws_subnet.private : v.id]
  private_subnet_cidrs = [for k, v in aws_subnet.private : v.cidr_block]

  kafka_cluster_map     = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.this.secret_string))
  broker_ports          = toset([for k, v in local.kafka_cluster_map : v.broker_port])
  bootstrap_brokers_tls = join(",", [for k, v in local.kafka_cluster_map : "${v.endpoint_url}:${v.broker_port}"])


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