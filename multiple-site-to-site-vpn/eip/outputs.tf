output "on_premises_1_peer_ip" {
  description = "IP of the On-Premises 1 VPN Peer"
  value       = aws_eip.on_premises_1_peer_ip.public_ip
}

output "on_premises_2_peer_ip" {
  description = "IP of the On-Premises 2 VPN Peer"
  value       = aws_eip.on_premises_2_peer_ip.public_ip
}
