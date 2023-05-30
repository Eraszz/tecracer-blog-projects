resource "aws_eip" "aws_public_encryption_domain" {
  domain   = "vpc"
}

resource "aws_eip" "on_premises_public_encryption_domain" {
  domain   = "vpc"
}

resource "aws_eip" "aws_peer_ip" {
  domain   = "vpc"
}

resource "aws_eip" "on_premises_peer_ip" {
  domain   = "vpc"
}
