variable "ami_id" {
  description = "ID of the AMI."
  type        = string
}

variable "account_ids" {
  description = "IDs of the accounts the AMI should be shared with."
  type        = set(string)
}
