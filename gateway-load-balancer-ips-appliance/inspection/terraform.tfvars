vpc_cidr_block = "10.1.0.0/16"

public_subnets = {
  subnet_a = {
    cidr_block        = "10.1.0.0/24"
    availability_zone = "eu-central-1a"
  }
  subnet_b = {
    cidr_block        = "10.1.1.0/24"
    availability_zone = "eu-central-1b"
  }
}

private_subnets = {
  subnet_a = {
    cidr_block        = "10.1.2.0/24"
    availability_zone = "eu-central-1a"
  }
  subnet_b = {
    cidr_block        = "10.1.3.0/24"
    availability_zone = "eu-central-1b"
  }
}

application_name               = "gwlb-firewall-ips-inspection"
allowed_service_principal_arns = ["arn:aws:iam::xxxxxxxxxxx:root"]
custom_rule_file_name          = "custom.rules"