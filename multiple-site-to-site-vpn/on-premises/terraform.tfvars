on_premises_networks = {
  on-premises-1 = {
    vpc_cidr_block                  = "10.0.0.0/16"
    opposite_on_premises_cidr_range = "10.1.0.0/16"
    aws_peer_ips                    = ["xxxxxxxxxx", "xxxxxxxxxx"]
    on_premises_peer_ip             = "xxxxxxxxxx"
  }
  on-premises-2 = {
    vpc_cidr_block                  = "10.1.0.0/16"
    opposite_on_premises_cidr_range = "10.0.0.0/16"
    aws_peer_ips                    = ["xxxxxxxxxx", "xxxxxxxxxx"]
    on_premises_peer_ip             = "xxxxxxxxxx"
  }
}

aws_cidr_range = "172.16.0.0/16"
