
################################################################################
# S3
################################################################################

resource "aws_s3_bucket" "this" {
}


################################################################################
# EC2
################################################################################

resource "aws_instance" "instance_A" {
  instance_type = "t2.large"
  ami           = data.aws_ami.ubuntu.id
}

resource "aws_instance" "instance_B" {
  instance_type = "t2.large"
  ami           = data.aws_ami.ubuntu.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


################################################################################
# IAM
################################################################################

resource "aws_iam_role" "this" {
  name = "example-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}