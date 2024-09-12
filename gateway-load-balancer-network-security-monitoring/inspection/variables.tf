variable "vpc_cidr_block" {
  description = "CIDR of vpc"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnets that should be created"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnets that should be created"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "allowed_service_principal_arns" {
  description = "List of the consumer ARNs allowed to connect to the VPC Endpoint Service and access the secret."
  type        = list(string)
}
