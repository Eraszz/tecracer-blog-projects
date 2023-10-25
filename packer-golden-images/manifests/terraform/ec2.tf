################################################################################
# EC2
################################################################################

resource "aws_instance" "this" {
  instance_type          = var.instance_type
  ami                    = var.ami_id
  subnet_id              = data.aws_subnets.default.ids[0]
  iam_instance_profile   = aws_iam_instance_profile.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

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

resource "aws_security_group" "this" {
  name   = var.application_name
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.this.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress" {
  security_group_id = aws_security_group.this.id

  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}


