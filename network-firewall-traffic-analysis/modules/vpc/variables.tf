################################################################################
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
################################################################################

variable "name" {
  description = "Name for the resources used in this module."
  type        = string
}

################################################################################
# VPC
################################################################################

variable "cidr_block" {
  description = "The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using ipv4_netmask_length."
  type        = string
}

variable "availability_zones" {
  description = "AZ for the subnet."
  type        = list(string)
}

variable "enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC."
  type        = bool
  default     = false
}

variable "enable_dns_support" {
  description = "A boolean flag to enable/disable DNS support in the VPC."
  type        = bool
  default     = true
}

################################################################################
# PUBLIC Subnets
################################################################################

variable "public_subnets" {
  description = "Configuration set for public IPv4 subnets."
  type        = list(string)
  default     = []
}

variable "public_custom_routes" {
  description = "Configuration map for custom public routes."
  type = list(object({
    destination_cidr_block      = optional(string)
    destination_ipv6_cidr_block = optional(string)
    destination_prefix_list_id  = optional(string)
    carrier_gateway_id          = optional(string)
    core_network_arn            = optional(string)
    egress_only_gateway_id      = optional(string)
    gateway_id                  = optional(string)
    nat_gateway_id              = optional(string)
    local_gateway_id            = optional(string)
    network_interface_id        = optional(string)
    transit_gateway_id          = optional(string)
    vpc_endpoint_id             = optional(string)
    vpc_peering_connection_id   = optional(string)
  }))
  default = []
}

################################################################################
# PRIVATE Subnets
################################################################################

variable "private_subnets" {
  description = "Configuration set for private IPv4 subnets."
  type        = list(string)
  default     = []
}

variable "create_nat_gateway" {
  description = "Bool to define if NAT Gateways should be created."
  type        = bool
  default     = false
}

variable "private_custom_routes" {
  description = "Configuration map for custom private routes."
  type = list(object({
    destination_cidr_block      = optional(string)
    destination_ipv6_cidr_block = optional(string)
    destination_prefix_list_id  = optional(string)
    carrier_gateway_id          = optional(string)
    core_network_arn            = optional(string)
    egress_only_gateway_id      = optional(string)
    gateway_id                  = optional(string)
    nat_gateway_id              = optional(string)
    local_gateway_id            = optional(string)
    network_interface_id        = optional(string)
    transit_gateway_id          = optional(string)
    vpc_endpoint_id             = optional(string)
    vpc_peering_connection_id   = optional(string)
  }))
  default = []
}

################################################################################
# TGW Subnets
################################################################################

variable "tgw_subnets" {
  description = "Configuration set for tgw IPv4 subnets."
  type        = list(string)
  default     = []
}

variable "tgw_custom_routes" {
  description = "Configuration map for custom tgw routes."
  type = list(object({
    destination_cidr_block      = optional(string)
    destination_ipv6_cidr_block = optional(string)
    destination_prefix_list_id  = optional(string)
    carrier_gateway_id          = optional(string)
    core_network_arn            = optional(string)
    egress_only_gateway_id      = optional(string)
    gateway_id                  = optional(string)
    nat_gateway_id              = optional(string)
    local_gateway_id            = optional(string)
    network_interface_id        = optional(string)
    transit_gateway_id          = optional(string)
    vpc_endpoint_id             = optional(string)
    vpc_peering_connection_id   = optional(string)
  }))
  default = []
}

variable "tgw_custom_routes_specific" {
  description = "Configuration map for custom tgw routes."
  type = list(object({
    destination_cidr_block      = optional(string)
    destination_ipv6_cidr_block = optional(string)
    destination_prefix_list_id  = optional(string)
    carrier_gateway_id          = optional(string)
    core_network_arn            = optional(string)
    egress_only_gateway_id      = optional(string)
    gateway_id                  = optional(string)
    nat_gateway_id              = optional(string)
    local_gateway_id            = optional(string)
    network_interface_id        = optional(string)
    transit_gateway_id          = optional(string)
    vpc_endpoint_id             = optional(string)
    vpc_peering_connection_id   = optional(string)
    availability_zone           = string
  }))
  default = []
}