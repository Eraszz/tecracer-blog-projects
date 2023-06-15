################################################################################
# DynamoDB Table
################################################################################

resource "aws_dynamodb_table" "this" {
  name = format("%s-%s", var.application_name, var.microservice_name)

  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "orderId"

  table_class = "STANDARD"

  attribute {
    name = "orderId"
    type = "S"
  }

  attribute {
    name = "orderDate"
    type = "S"
  }

  global_secondary_index {
    name            = "orderDateIndex"
    hash_key        = "orderDate"
    projection_type = "ALL"
  }
}
