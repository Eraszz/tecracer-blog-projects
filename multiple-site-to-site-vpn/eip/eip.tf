resource "aws_eip" "on_premises_1_peer_ip" {
  domain = "vpc"
}

resource "aws_eip" "on_premises_2_peer_ip" {
  domain = "vpc"
}

