variable "vpc_cidr_block" {
  description = "CIDR of vpc"
  type        = string
}

variable "gwlb_subnets" {
  description = "Map of GWLB subnets that should be created"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
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

variable "secret_name" {
  description = "Name of the secret that contains the GWLB details"
  type = string
}