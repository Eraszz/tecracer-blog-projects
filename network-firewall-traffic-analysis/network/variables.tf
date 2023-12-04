################################################################################
# General
################################################################################

variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "on_premises_cidr_range" {
  description = "CIDR Range of the on-premises network"
  type        = string
}

variable "aws_cidr_range" {
  description = "CIDR Range of the aws network"
  type        = string
}

variable "network_firewall_on_premises_action" {
  description = "Action the AWS Network Firewall should take for traffic coming from the On-Premises network"
  type        = string
}

################################################################################
# Ingress VPC
################################################################################

variable "ingress_vpc_cidr_range" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
}

variable "ingress_vpc_availability_zones" {
  description = "AZ for the subnet."
  type        = list(string)
}

variable "ingress_vpc_public_subnets" {
  description = "Configuration set for public IPv4 subnets."
  type        = list(string)
  default     = []
}

variable "ingress_vpc_tgw_subnets" {
  description = "Configuration set for tgw IPv4 subnets."
  type        = list(string)
  default     = []
}

################################################################################
# Egress VPC
################################################################################

variable "egress_vpc_cidr_range" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
}

variable "egress_vpc_availability_zones" {
  description = "AZ for the subnet."
  type        = list(string)
}

variable "egress_vpc_public_subnets" {
  description = "Configuration set for public IPv4 subnets."
  type        = list(string)
  default     = []
}

variable "egress_vpc_tgw_subnets" {
  description = "Configuration set for tgw IPv4 subnets."
  type        = list(string)
  default     = []
}

################################################################################
# Inspection VPC
################################################################################

variable "inspection_vpc_cidr_range" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
}

variable "inspection_vpc_availability_zones" {
  description = "AZ for the subnet."
  type        = list(string)
}

variable "inspection_vpc_firewall_subnets" {
  description = "Configuration set for firewall IPv4 subnets."
  type        = list(string)
  default     = []
}

variable "inspection_vpc_tgw_subnets" {
  description = "Configuration set for tgw IPv4 subnets."
  type        = list(string)
  default     = []
}

################################################################################
# Workload VPC
################################################################################

variable "workload_vpc_cidr_range" {
  description = "The IPv4 CIDR block for the VPC"
  type        = string
}

variable "workload_vpc_availability_zones" {
  description = "AZ for the subnet."
  type        = list(string)
}

variable "workload_vpc_private_subnets" {
  description = "Configuration set for private IPv4 subnets."
  type        = list(string)
  default     = []
}

variable "workload_vpc_tgw_subnets" {
  description = "Configuration set for tgw IPv4 subnets."
  type        = list(string)
  default     = []
}

################################################################################
# On-Premises VPC
################################################################################

variable "on_prem_vpc_availability_zones" {
  description = "AZ for the subnet."
  type        = list(string)
}

variable "on_prem_vpc_private_subnets" {
  description = "Configuration set for private IPv4 subnets."
  type        = list(string)
  default     = []
}

