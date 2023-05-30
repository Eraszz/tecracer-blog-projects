################################################################################
# Server EC2
################################################################################

resource "aws_instance" "server" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.amazon_2.id
  subnet_id              = local.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.server.id]

  private_ip = "192.168.1.100"

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {"Name" = "Server"}
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
# Server Security Group
################################################################################

resource "aws_security_group" "server" {
  name   = "${var.application_name}-server"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "server_ingress" {
  security_group_id = aws_security_group.server.id

  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  source_security_group_id = aws_security_group.lan_eni.id
}
