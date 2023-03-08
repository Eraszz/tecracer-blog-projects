################################################################################
# Lambda Outputs
################################################################################

output "function_name" {
  description = "Name of the lambda function."
  value       = aws_lambda_function.this.function_name
}

output "arn" {
  description = "Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "ARN to be used for invoking Lambda Function from API Gateway - to be used in aws_api_gateway_integration's uri."
  value       = aws_lambda_function.this.invoke_arn
}

output "last_modified" {
  description = "Date this resource was last modified."
  value       = aws_lambda_function.this.last_modified
}

output "qualified_arn" {
  description = "ARN identifying your Lambda Function Version (if versioning is enabled via publish = true)."
  value       = aws_lambda_function.this.qualified_arn
}

output "source_code_size" {
  description = "Size in bytes of the function .zip file."
  value       = aws_lambda_function.this.source_code_size
}

output "version" {
  description = "Latest published version of your Lambda Function."
  value       = aws_lambda_function.this.version
}

output "cloudwatch_group_arn" {
  description = "The Amazon Resource Name (ARN) specifying the log group."
  value       = aws_cloudwatch_log_group.this.arn
}


################################################################################
# Lambda Alias Outputs
################################################################################

output "alias_arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda function alias."
  value       = aws_lambda_alias.this.arn
}

output "alias_invoke_arn" {
  description = "The ARN to be used for invoking Lambda Function from API Gateway - to be used in aws_api_gateway_integration's uri"
  value       = aws_lambda_alias.this.invoke_arn
}
