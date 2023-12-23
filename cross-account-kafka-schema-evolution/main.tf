
module "consumer" {
  source = "./consumer"

  providers = {
    aws = aws.consumer
  }

  application_name = format("%s-%s", var.application_name, "consumer")

  vpc_cidr_block                = var.consumer_cidr_block
  availability_zones            = var.availability_zones
  kafka_cluster_information_map = module.producer.kafka_cluster_information_map

  kafka_topic_name               = var.application_name
  glue_schema_registry_name      = module.producer.glue_schema_registry_name
  cross_account_glue_access_role = module.producer.cross_account_glue_access_role
}



module "producer" {
  source = "./producer"

  providers = {
    aws = aws.producer
  }

  application_name = format("%s-%s", var.application_name, "producer")

  vpc_cidr_block                 = var.producer_cidr_block
  availability_zones             = var.availability_zones
  allowed_service_principal_arns = ["arn:aws:iam::${data.aws_caller_identity.consumer.account_id}:root"]

  kafka_topic_name = var.application_name
  schema_name      = "sensor"
  schema_namespace = var.application_name
}

################################################################################
# Get Current Consumer AWS Account ID
################################################################################

data "aws_caller_identity" "consumer" {
  provider = aws.consumer
}