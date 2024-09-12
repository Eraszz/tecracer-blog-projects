vpc_cidr_block = "10.0.0.0/16"

gwlb_subnets = {
  subnet_a = {
    cidr_block        = "10.0.0.0/24"
    availability_zone = "eu-central-1a"
  }
  subnet_b = {
    cidr_block        = "10.0.1.0/24"
    availability_zone = "eu-central-1b"
  }
}

public_subnets = {
  subnet_a = {
    cidr_block        = "10.0.2.0/24"
    availability_zone = "eu-central-1a"
  }
  subnet_b = {
    cidr_block        = "10.0.3.0/24"
    availability_zone = "eu-central-1b"
  }
}

private_subnets = {
  subnet_a = {
    cidr_block        = "10.0.4.0/24"
    availability_zone = "eu-central-1a"
  }
  subnet_b = {
    cidr_block        = "10.0.5.0/24"
    availability_zone = "eu-central-1b"
  }
}

application_name = "gwlb-nsm-workload"
secretsmanager_secret_arn      = "arn:aws:secretsmanager:eu-central-1:XXXXXXXXXXX:secret:gwlb-nsm-inspection-cbTcI0"