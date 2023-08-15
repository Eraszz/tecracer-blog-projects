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
# DHCP Option Set
################################################################################

resource "aws_vpc_dhcp_options" "this" {
  domain_name         = format("%s.com", var.application_name)
  domain_name_servers = [var.dns_server_ip]

}

resource "aws_vpc_dhcp_options_association" "this" {
  vpc_id          = data.aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this.id
}