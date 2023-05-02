vpc_cidr_block = "10.0.0.0/16"

public_subnets = {
  subnet_1 = {
    cidr_block        = "10.0.0.0/24"
    availability_zone = "eu-central-1a"
  }
  subnet_2 = {
    cidr_block        = "10.0.1.0/24"
    availability_zone = "eu-central-1b"
  }
}

private_subnets = {
  subnet_1 = {
    cidr_block        = "10.0.2.0/24"
    availability_zone = "eu-central-1a"
  }
  subnet_2 = {
    cidr_block        = "10.0.3.0/24"
    availability_zone = "eu-central-1b"
  }
}

application_name = "cross-account-msk-data-streaming"