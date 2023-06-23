################################################################################
# Server EC2
################################################################################

resource "aws_instance" "server" {
  instance_type          = "t3.medium"
  ami                    = data.aws_ami.nginx.id
  subnet_id              = local.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.server.id]

  private_ip = "172.16.1.100"

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = { "Name" = "Server" }
}


################################################################################
# Get newest Linux 2 AMI
################################################################################

data "aws_ami" "nginx" {
  most_recent = true

  filter {
    name   = "name"
    values = ["nginx-plus-amazon-linux-2-v1.10-x86_64-developer-*"]
  }
}


################################################################################
# Server Security Group
################################################################################

resource "aws_security_group" "server" {
  name   = "${var.application_name}-server"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "server_http_ingress" {
  security_group_id = aws_security_group.server.id

  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lan_eni.id
}

resource "aws_security_group_rule" "server_icmp_ingress" {
  security_group_id = aws_security_group.server.id

  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "icmp"
  source_security_group_id = aws_security_group.lan_eni.id
}
