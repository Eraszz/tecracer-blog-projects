################################################################################
# DynamoDB Table (IOT Data)
################################################################################

resource "aws_dynamodb_table" "this" {
  name = var.application_name

  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "deviceId"
  range_key    = "timestamp"

  table_class = "STANDARD"

  attribute {
    name = "deviceId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }
}
