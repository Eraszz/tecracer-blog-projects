################################################################################
# Client EC2
################################################################################

resource "aws_instance" "client" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.amazon_2.id
  subnet_id              = local.private_subnet_ids_client[0]
  iam_instance_profile   = aws_iam_instance_profile.this.name
  vpc_security_group_ids = [aws_security_group.client.id]

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = { "Name" = "${var.application_name}-Client" }

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

resource "aws_iam_role" "this" {
  name = var.application_name

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

resource "aws_iam_instance_profile" "this" {
  name = "${aws_iam_role.this.name}-ip"
  role = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


################################################################################
# Client Security Group
################################################################################

resource "aws_security_group" "client" {
  name   = "${var.application_name}-client"
  vpc_id = aws_vpc.client.id
}

resource "aws_security_group_rule" "client_egress" {
  security_group_id = aws_security_group.client.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "client_icmp_ingress" {
  security_group_id = aws_security_group.client.id

  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = [for value in var.on_premises_networks : value.cidr_range]
}
