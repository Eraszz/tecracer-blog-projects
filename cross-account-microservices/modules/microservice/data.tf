################################################################################
# Get Current region
################################################################################

data "aws_region" "current" {}


################################################################################
# Get DynamoDB prefix list
################################################################################

data "aws_ec2_managed_prefix_list" "this" {
  name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
}


################################################################################
# Get API Gateway VPC Endpoint ID via Secrets Manager
################################################################################

data "aws_secretsmanager_secret" "this" {
  name = var.application_name
}

data "aws_secretsmanager_secret_version" "this" {
  secret_id = data.aws_secretsmanager_secret.this.id
}