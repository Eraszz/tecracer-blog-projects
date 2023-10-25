################################################################################
# Outputs
################################################################################

output "remote_state_s3_id" {
  description = "The name of the bucket."
  value       = aws_s3_bucket.state_storage.id
}

output "remote_state_dynamodb_id" {
  description = "The name of the table"
  value       = aws_dynamodb_table.state_storage.id
}

output "remote_state_kms_alias" {
  description = "The Alias of the KMS key"
  value       = aws_kms_alias.state_storage.id
}