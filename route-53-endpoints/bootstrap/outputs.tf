output "vpn_output_map" {
  description = "Output map containing all the necessary VPN information"
  value       = module.aws_site.vpn_output_map
  sensitive   = true
}

output "aws_site_client_ip" {
  description = "IP addresse of the client EC2"
  value       = module.aws_site.client_ip
}

output "on_premises_domain_name" {
  description = "Name of the On-Premises domain"
  value       = module.on_premises.domain_name
}

output "on_premises_dns_server_ip" {
  description = "IP of the On-Premises DNS server"
  value       = module.on_premises.dns_server_ip
}