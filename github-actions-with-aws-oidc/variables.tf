
variable "org_or_user_name" {
  description = "Name of GitHub Org or User that can assume IAM role"
  type        = string
  default     = "PUT_YOUR_ORG_OR_USER_HERE"
}

## The name of the repository MUST be a name that you currently DO NOT possess! The repository will be created using Terraform.

variable "repository_name" {
  description = "Name of GitHub repository that can assume IAM role"
  type        = string
  default     = "PUT_YOUR_REPO_NAME_HERE"
}
