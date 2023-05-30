output "aws_public_encryption_domain" {
    description = "IP of the public encryption domain for the AWS site"
    value = aws_eip.aws_public_encryption_domain.public_ip
}

output "on_premises_public_encryption_domain" {
    description = "IP of the public encryption domain for the On-Premises site"
    value = aws_eip.on_premises_public_encryption_domain.public_ip
}

output "aws_peer_ip" {
    description = "IP of the AWS VPN Peer"
    value = aws_eip.aws_peer_ip.public_ip
}

output "on_premises_peer_ip" {
    description = "IP of the On-Premises VPN Peer"
    value = aws_eip.on_premises_peer_ip.public_ip
}
