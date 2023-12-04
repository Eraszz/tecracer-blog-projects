output "vpn_peer_ip" {
  description = "IP of the On-Premises VPN Peer"
  value       = aws_eip.this.public_ip
}

output "lan_eni_id" {
  description = "IP of the LAN eni."
  value       = aws_network_interface.this.id
}