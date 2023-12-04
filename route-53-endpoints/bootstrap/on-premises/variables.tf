variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR of vpc"
  type        = string
}

variable "availability_zones" {
  description = "AZ to deploy network to"
  type        = list(string)
}

variable "aws_network" {
  description = "Object of AWS network"
  type = object({
    peer_ips       = list(string)
    preshared_keys = list(string)
    cidr_range     = string
    domain_name    = string
  })
}