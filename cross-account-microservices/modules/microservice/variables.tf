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

variable "microservice_name" {
  description = "Name/Topic of the microservice."
  type        = string
}

variable "microservice_order_options" {
  description = "Order options of the microservice."
  type        = list(string)
}

variable "domain_name" {
  description = "Name of the custom API Gateway domain."
  type        = string
}

variable "api_gateway_definition_template" {
  description = "YAML file describing the API Gateway definition."
  type        = string
}

variable "secretsmanager_secret_arn" {
  description = "ARN of the secretsmanager secret that stores the API Gateway VPC Endpoint ID."
  type        = string
}