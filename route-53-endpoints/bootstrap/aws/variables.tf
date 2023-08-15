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

variable "on_premises_network" {
  description = "Object of On-Premises network"
  type = object({
    customer_gateway_ip = string
    cidr_range          = string
    bgp_asn             = number
  })
}
