data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


################################################################################
# Get Ubuntu AMI
################################################################################

data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240423"]
  }
  owners = ["amazon"]
}

################################################################################
# Get Public IP
################################################################################

data "http" "this" {
  url = "https://checkip.amazonaws.com"
}