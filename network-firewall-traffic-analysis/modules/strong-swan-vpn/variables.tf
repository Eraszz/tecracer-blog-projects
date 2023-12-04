################################################################################
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
################################################################################

variable "name" {
  description = "Name for the resources used in this module."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the VPN should be launched in."
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the public subnet the WAN interface of the VPN should be placed in."
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the private subnet the LAN interface of the VPN should be placed in."
  type        = string
}

variable "aws_network" {
  description = "Object of AWS network"
  type = object({
    peer_ips       = list(string)
    preshared_keys = list(string)
    cidr_range     = string
  })
}