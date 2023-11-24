################################################################################
# NAT Gateway
################################################################################

resource "aws_eip" "client" {
  domain = "vpc"

  tags = {
    Name = format("%s-nat-gateway", "on-prem"),
  }
}

resource "aws_nat_gateway" "client" {
  subnet_id     = aws_default_subnet.default_public[keys(aws_default_subnet.default_public)[0]].id
  allocation_id = aws_eip.client.id

  tags = {
    Name = format("%s-nat-gateway", "on-prem"),
  }
}
################################################################################
# Default Private subnets
################################################################################

resource "aws_default_subnet" "default_public" {
  for_each          = toset(var.on_prem_vpc_availability_zones)
  availability_zone = each.value

  tags = {
    Name = format("public-%s-%s", "on-prem", each.value)
  }
}

################################################################################
# Default Private subnets
################################################################################

resource "aws_subnet" "default_private" {
  for_each = toset(var.on_prem_vpc_private_subnets)

  vpc_id = data.aws_vpc.default.id

  cidr_block        = each.value
  availability_zone = var.on_prem_vpc_availability_zones[index(var.on_prem_vpc_private_subnets, each.value)]

  tags = {
    Name = format("private-%s-%s", "on-prem", var.on_prem_vpc_availability_zones[index(var.on_prem_vpc_private_subnets, each.value)])
  }
}

################################################################################
# Default Private Route table
################################################################################

resource "aws_route_table" "default_private" {
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = format("%s-private", "on-prem"),
    tier = "private"
  }
}

resource "aws_route" "vpn" {
  route_table_id         = aws_route_table.default_private.id
  destination_cidr_block = var.aws_cidr_range
  network_interface_id   = module.vpn.lan_eni_id
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.default_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.client.id
}

################################################################################
# Private Route Association
################################################################################

resource "aws_route_table_association" "default_private" {
  for_each = aws_subnet.default_private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.default_private.id
}

module "vpn" {
  source = "../modules/strong-swan-vpn"

  name              = "on-prem"
  vpc_id            = data.aws_vpc.default.id
  private_subnet_id = aws_subnet.default_private[keys(aws_subnet.default_private)[0]].id
  public_subnet_id  = aws_default_subnet.default_public[keys(aws_default_subnet.default_public)[0]].id
  aws_network = {
    cidr_range = var.aws_cidr_range
    peer_ips = [
      aws_vpn_connection.this.tunnel1_address,
      aws_vpn_connection.this.tunnel2_address
    ]
    preshared_keys = [
      aws_vpn_connection.this.tunnel1_preshared_key,
      aws_vpn_connection.this.tunnel2_preshared_key
    ]
  }
}


################################################################################
# On-Premises Client EC2
################################################################################

resource "aws_instance" "client" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.amazon_2.id
  subnet_id              = aws_subnet.default_private[keys(aws_subnet.default_private)[0]].id
  iam_instance_profile   = aws_iam_instance_profile.client.name
  vpc_security_group_ids = [aws_security_group.client.id]

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = { "Name" = "${var.application_name}-on-prem-client" }

}


################################################################################
# Get newest Linux 2 AMI
################################################################################

data "aws_ami" "amazon_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}


################################################################################
# EC2 Instance Profile
################################################################################

resource "aws_iam_role" "client" {
  name = "${var.application_name}-on-prem-client"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "client" {
  name = "${aws_iam_role.client.name}-ip"
  role = aws_iam_role.client.name
}

resource "aws_iam_role_policy_attachment" "client" {
  role       = aws_iam_role.client.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


################################################################################
# Client Security Group
################################################################################

resource "aws_security_group" "client" {
  name   = "${var.application_name}-on-prem-client"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "client_egress" {
  security_group_id = aws_security_group.client.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}