
module "consumer" {
  source = "./consumer"

  application_name = format("%s-%s", var.application_name, "consumer")

  vpc_cidr_block                = var.consumer_cidr_block
  availability_zones            = var.availability_zones
  kafka_cluster_information_map = module.producer.kafka_cluster_information_map

  kafka_topic_name = var.application_name
}


module "producer" {
  source = "./producer"

  application_name = format("%s-%s", var.application_name, "producer")

  vpc_cidr_block                 = var.producer_cidr_block
  availability_zones             = var.availability_zones
  allowed_service_principal_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  kafka_topic_name = var.application_name
  schema_name      = "sensor"
  schema_pathname  = format("%s_%s.avsc", "schema", var.schema_version)
}

################################################################################
# Get Current AWS Account ID
################################################################################

data "aws_caller_identity" "current" {}