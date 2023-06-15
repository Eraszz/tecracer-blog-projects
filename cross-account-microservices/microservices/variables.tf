variable "vpc_cidr_block" {
  description = "CIDR of VPC."
  type        = string
}

variable "private_subnets" {
  description = "Map of private subnets that should be created."
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "application_name" {
  description = "Name of the application."
  type        = string
}

variable "microservices" {
  description = "List of microservices to create."
  type        = map(list(string))
}
