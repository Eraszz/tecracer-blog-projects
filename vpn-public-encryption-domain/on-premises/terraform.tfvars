vpc_cidr_block = "192.168.0.0/16"

public_subnets = {
  subnet_1 = {
    cidr_block        = "192.168.0.0/24"
    availability_zone = "eu-central-1a"
  }
}

private_subnets = {
  subnet_1 = {
    cidr_block        = "192.168.1.0/24"
    availability_zone = "eu-central-1a"
  }
}

application_name          = "onprem-site-vpn-public-encryption-domain"

aws_public_encryption_domain_ip = "xxxxxxxxxx"
aws_peer_ip = "xxxxxxxxxx"
on_premises_peer_ip = "xxxxxxxxxx"