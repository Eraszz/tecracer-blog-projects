variable "vpc_cidr_block_client" {
  description = "CIDR of vpc"
  type        = string
}

variable "vpc_cidr_block_egress" {
  description = "CIDR of vpc"
  type        = string
}

variable "availability_zones" {
  description = "AZ to deploy network to"
  type        = list(string)
  default     = ["eu-central-1a"]
}

variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "on_premises_networks" {
  description = "Map of On-Premises networks to connect to"
  type = map(object({
    customer_gateway_ip = string
    cidr_range          = string
    bgp_asn             = number
  }))
}
