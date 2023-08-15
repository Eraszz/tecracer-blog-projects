variable "aws_cidr_block" {
  description = "CIDR of AWS vpc"
  type        = string
}

variable "on_premises_cidr_block" {
  description = "CIDR of On-Premises vpc"
  type        = string
}

variable "availability_zones" {
  description = "AZ to deploy network to"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}