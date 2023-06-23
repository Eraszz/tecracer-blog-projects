output "network_controller_instance_id" {
  description = "ID of the Network Controller EC2 instance"
  value       = aws_instance.network_controller.id
}