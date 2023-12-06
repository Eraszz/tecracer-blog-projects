output "kafka_cluster_information_map" {
  description = "MSK Kafka cluster information for consumer."
  value       = local.kafka_cluster_information_map
}

output "glue_schema_registry_name" {
  description = "Name of the Glue Schema Registry."
  value       = aws_glue_registry.this.registry_name
}

output "cross_account_glue_access_role" {
  description = "Role to assume in order to access Schema Registry."
  value       = aws_iam_role.cross_account_glue_access.arn
}