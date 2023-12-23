variable "consumer_cidr_block" {
  description = "CIDR of AWS vpc"
  type        = string
}

variable "producer_cidr_block" {
  description = "CIDR of On-Premises vpc"
  type        = string
}

variable "availability_zones" {
  description = "AZ to deploy network to"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "application_name" {
  description = "Name of the application."
  type        = string
}
