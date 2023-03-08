################################################################################
# Outputs
################################################################################

output "swagger_ui_endpoint" {
  description = "Endpoint Swagger UI can be reached over"
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.eu-central-1.amazonaws.com/v1/api-docs/"
}