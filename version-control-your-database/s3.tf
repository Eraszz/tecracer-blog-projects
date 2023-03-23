################################################################################
# S3 Buckets for each managed database
################################################################################

resource "aws_s3_bucket" "this" {
  for_each = toset(var.flyway_managed_databases)

  bucket_prefix = lower(each.value)
  force_destroy = true
}

################################################################################
# S3 notification trigger
################################################################################

resource "aws_s3_bucket_notification" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id
  lambda_function {
    events              = ["s3:ObjectCreated:*"]
    lambda_function_arn = aws_lambda_function.flyway_trigger.arn
    filter_suffix       = ".sql"
  }
  depends_on = [
    aws_lambda_permission.flyway_trigger
  ]
}

################################################################################
# ParameterStore variables for S3 Bucket mapping
################################################################################

resource "aws_ssm_parameter" "s3_mapping" {
for_each = aws_s3_bucket.this
  name = "/flyway/s3-mapping/${each.value.id}"
  type = "StringList"
  value = jsonencode(
    {
      schema        = each.key
      flywayVersion = var.flyway_version
      flywayConf  = var.flyway_conf
    }
  )
}