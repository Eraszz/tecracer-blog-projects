################################################################################
# General
################################################################################

application_name       = "network-firewall-traffic-analysis"
on_premises_cidr_range = "172.31.0.0/16"
aws_cidr_range         = "10.0.0.0/8"

network_firewall_on_premises_action = "DROP"

################################################################################
# Ingress VPC
################################################################################

ingress_vpc_cidr_range         = "10.0.0.0/16"
ingress_vpc_availability_zones = ["eu-central-1a", "eu-central-1b"]
ingress_vpc_public_subnets     = ["10.0.16.0/20", "10.0.32.0/20"]
ingress_vpc_tgw_subnets        = ["10.0.48.0/20", "10.0.64.0/20"]

################################################################################
# Egress VPC
################################################################################

egress_vpc_cidr_range         = "10.1.0.0/16"
egress_vpc_availability_zones = ["eu-central-1a", "eu-central-1b"]
egress_vpc_public_subnets     = ["10.1.16.0/20", "10.1.32.0/20"]
egress_vpc_tgw_subnets        = ["10.1.48.0/20", "10.1.64.0/20"]

################################################################################
# Inspection VPC
################################################################################

inspection_vpc_cidr_range         = "10.2.0.0/16"
inspection_vpc_availability_zones = ["eu-central-1a", "eu-central-1b"]
inspection_vpc_firewall_subnets   = ["10.2.16.0/20", "10.2.32.0/20"]
inspection_vpc_tgw_subnets        = ["10.2.48.0/20", "10.2.64.0/20"]

################################################################################
# Workload VPC
################################################################################

workload_vpc_cidr_range         = "10.3.0.0/16"
workload_vpc_availability_zones = ["eu-central-1a", "eu-central-1b"]
workload_vpc_private_subnets    = ["10.3.16.0/20", "10.3.32.0/20"]
workload_vpc_tgw_subnets        = ["10.3.48.0/20", "10.3.64.0/20"]

################################################################################
# On-Premises VPC
################################################################################

on_prem_vpc_availability_zones = ["eu-central-1a"]
on_prem_vpc_private_subnets    = ["172.31.48.0/20"]
