vpc_cidr_block = "192.168.0.0/16"

private_subnets = {
  subnet_1 = {
    cidr_block        = "192.168.2.0/24"
    availability_zone = "eu-central-1a"
  }
  subnet_2 = {
    cidr_block        = "192.168.3.0/24"
    availability_zone = "eu-central-1b"
  }
}

application_name = "cross-account-microservices"

microservices = {
  beverage = ["tea", "coffee", "water"],
  food     = ["pizza", "hamburger", "salat"]
}

secretsmanager_secret_arn = "xxxxxxxxxxx"