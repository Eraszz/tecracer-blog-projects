vpc_cidr_block = "172.16.0.0/16"

public_subnets = {
  subnet_1 = {
    cidr_block        = "172.16.0.0/24"
    availability_zone = "eu-central-1a"
  }
}

private_subnets = {
  subnet_1 = {
    cidr_block        = "172.16.1.0/24"
    availability_zone = "eu-central-1a"
  }
}

application_name = "aws-site-vpn-public-encryption-domain"

on_premises_public_encryption_domain = "xxxxxxxxxx"
on_premises_peer_ip                  = "xxxxxxxxxx"
aws_peer_ip                          = "xxxxxxxxxx"
