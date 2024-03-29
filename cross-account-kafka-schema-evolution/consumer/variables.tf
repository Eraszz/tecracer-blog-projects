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

variable "kafka_cluster_information_map" {
  description = "Name of the producer secret."
  type = map(object({
    endpoint_url = string
    broker_port  = string
    service_name = string
  }))
}

variable "kafka_topic_name" {
  description = "Name of the Kafka topic."
  type        = string
}

variable "glue_schema_registry_name" {
  description = "Name of the Glue Schema Registry"
  type        = string
}

variable "cross_account_glue_access_role" {
  description = "Role to assume in order to access Schema Registry."
  type        = string
}