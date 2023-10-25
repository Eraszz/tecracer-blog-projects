variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "sns_endpoint" {
  description = "Terraform version to install in CodeBuild Container"
  type        = string
}

variable "aws_kms_alias" {
  description = "Alias of the KMS key used for the state storage."
  type        = string
}

variable "tf_state_storage_bucket_name" {
  description = "Name of the state storage bucket."
  type        = string
}

variable "tf_state_storage_dynamodb_lock_name" {
  description = "Name of the dynamoDB table to lock the terraform state."
  type        = string
}