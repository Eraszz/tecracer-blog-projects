variable "name" {
  description = "Name of the Load Balancer and related resources."
  type        = string
}

variable "subnets" {
  description = "List of Subnet to deploy Load Balancer into."
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of Target Group VPC."
  type        = string
}

variable "port" {
  description = "Port to listen and forward traffic to."
  type        = number
}

variable "target_id" {
  description = "ID of target to attach to Target Group"
  type        = string
}

variable "allowed_service_principal_arns" {
  description = "List of principal ARNs that are allowed to accees the vpc endpoint service."
  type        = list(string)
}