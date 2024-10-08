################################################################################
# Server EC2
################################################################################

resource "aws_instance" "server" {
  instance_type          = "t3.medium"
  ami                    = data.aws_ami.nginx.id
  subnet_id              = aws_subnet.private[keys(aws_subnet.private)[0]].id
  vpc_security_group_ids = [aws_security_group.server.id]

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
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "server_engress" {
  security_group_id = aws_security_group.server.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}