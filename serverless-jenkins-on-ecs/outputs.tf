output "private_subnet_ids" {
  description = "List of private subnet ids"
  value       = join(",", local.private_subnet_ids)
}

output "ecs_jenkins_agent_security_group_id" {
  description = "ID of the Jenkins agent security group"
  value       = aws_security_group.ecs_jenkins_agent.id
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role"
  value       = aws_iam_role.execution.arn
}

output "ecs_agent_role_arn" {
  description = "ARN of the agent task role"
  value       = aws_iam_role.agent.arn
}

output "ecs_cloudwatch_log_group_name" {
  description = "Name of the ECS CloudWatch Log group"
  value       = aws_cloudwatch_log_group.this.name
}

output "jenkins_controller_agent_tunnel_connection" {
  description = "Tunnel connection string"
  value       = "jenkins-controller.${var.application_name}:50000"
}

output "jenkins_url" {
  description = "URL of the Jenkins server"
  value       = "http://${aws_lb.this.dns_name}"
}