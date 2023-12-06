variable "application_name" {
  description = "Name of the application."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR of VPC."
  type        = string
}

variable "availability_zones" {
  description = "AZ to deploy network to."
  type        = list(string)
}

variable "allowed_service_principal_arns" {
  description = "List of the consumer ARNs allowed to connect to the VPC Endpoint Service and access the secret."
  type        = list(string)
}

variable "schema_namespace" {
  description = "Namespace of the Sensor schema."
  type        = string
}

variable "schema_name" {
  description = "Name of the Sensor schema."
  type        = string
}

variable "kafka_topic_name" {
  description = "Name of the Kafka topic."
  type        = string
}
