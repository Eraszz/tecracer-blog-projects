################################################################################
# MSK Cluster Broker Info
################################################################################

data "aws_msk_broker_nodes" "this" {
  cluster_arn = aws_msk_cluster.this.arn
}


################################################################################
# MSK Cluster
################################################################################

resource "aws_msk_cluster" "this" {

  cluster_name           = var.application_name
  kafka_version          = "2.8.1"
  number_of_broker_nodes = local.number_of_broker_nodes

  broker_node_group_info {
    client_subnets  = local.private_subnet_ids
    instance_type   = "kafka.t3.small"
    security_groups = [aws_security_group.msk.id]

    storage_info {
      ebs_storage_info {
        volume_size = 8
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }
}

################################################################################
# MSK Cloudwatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "msk" {
  name              = "/aws/msk/${var.application_name}"
  retention_in_days = 30
}

################################################################################
# MSK Security Group
################################################################################

resource "aws_security_group" "msk" {
  name   = format("%s-%s", var.application_name, "msk")
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "msk_ingress" {
  security_group_id = aws_security_group.msk.id

  type        = "ingress"
  from_port   = local.broker_port
  to_port     = local.broker_port
  protocol    = "tcp"
  cidr_blocks = local.private_subnet_cidrs
}

resource "aws_security_group_rule" "msk_egress" {
  security_group_id = aws_security_group.msk.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}
