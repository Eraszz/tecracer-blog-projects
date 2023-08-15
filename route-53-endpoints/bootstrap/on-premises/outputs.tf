output "peer_ip" {
  description = "IP of the On-Premises VPN Peer"
  value       = aws_eip.this.public_ip
}

output "domain_name" {
  description = "Name of the On-Premises domain"
  value       = "${var.application_name}.com"
}

output "dns_server_ip" {
  description = "IP of the On-Premises DNS server"
  value       = local.dns_server_ip
}
