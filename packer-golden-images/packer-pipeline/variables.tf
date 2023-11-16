variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "sns_endpoint" {
  description = "Terraform version to install in CodeBuild Container"
  type        = string
}

variable "account_ids" {
  description = "IDs of the accounts the AMI should be shared with."
  type        = map(string)
}