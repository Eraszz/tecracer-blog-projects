################################################################################
# Get VPC
################################################################################

data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [var.application_name]
  }
}


################################################################################
# Get List of private Subnet IDs
################################################################################


data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}
