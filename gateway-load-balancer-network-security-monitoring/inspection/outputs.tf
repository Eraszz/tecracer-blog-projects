output "gwlb_secretsmanager_secret_arn" {
  description = "ARN of the Secrets Manager secret responsible for storing the Gateway Load Balancer Endpoint connection information."
  value = aws_secretsmanager_secret.gwlb.arn
}

output "opensearch_dashboard_endpoint" {
  description = "Endpoint of the AWS OpenSearch dashboard."
  value = aws_opensearch_domain.this.dashboard_endpoint
}

output "opensearch_secretsmanager_secret_name" {
  description = "Name of the Secrets Manager secret that stores the login credentials for the OpenSearch Dashboard."
  value = aws_secretsmanager_secret.opensearch.name
}