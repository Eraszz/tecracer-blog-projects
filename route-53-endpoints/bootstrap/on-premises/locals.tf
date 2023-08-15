locals {

  public_subnets = { for index, v in var.availability_zones : "subnet_${index}" =>
    {
      cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, index)
      availability_zone = v
    }
  }

  private_subnets = { for index, v in var.availability_zones : "subnet_${index}" =>
    {
      cidr_block        = cidrsubnet(var.vpc_cidr_block, 8, index + 128)
      availability_zone = v
    }
  }

  aws_peer_ips_cidr = formatlist("%s/32", var.aws_network.peer_ips)

  public_subnet_ids   = [for k, v in aws_subnet.public : v.id]
  public_subnet_cidrs = [for k, v in aws_subnet.public : v.cidr_block]

  private_subnet_ids   = [for k, v in aws_subnet.private : v.id]
  private_subnet_cidrs = [for k, v in aws_subnet.private : v.cidr_block]

  dns_server_ip = cidrhost(local.private_subnet_cidrs[0], 10)
  server_ip     = cidrhost(local.private_subnet_cidrs[0], 20)
}
