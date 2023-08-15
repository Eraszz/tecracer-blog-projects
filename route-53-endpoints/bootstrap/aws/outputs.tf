output "vpn_output_map" {
  description = "Output map containing all the necessary VPN information"
  value       = local.vpn_output_map
  sensitive   = true
}

output "client_ip" {
  description = "IP addresse of the client EC2"
  value       = aws_instance.client.private_ip
}