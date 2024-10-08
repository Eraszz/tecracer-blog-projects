################################################################################
# Suricata EC2 Launch Template
################################################################################

resource "aws_launch_template" "this" {
  name = var.application_name

  instance_type          = "t3.xlarge"
  image_id               = data.aws_ami.this.id
  vpc_security_group_ids = [aws_security_group.suricata.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.suricata.arn
  }

  user_data = base64encode(templatefile("${path.module}/src/bootstrap.sh", {
    aws_region                       = data.aws_region.current.name
    vpc_id                           = aws_vpc.this.id
    parameter_store_config_file_name = aws_ssm_parameter.this.name
    efs_id                           = aws_efs_file_system.this.id
    custom_rule_file_name            = var.custom_rule_file_name
    s3_bucket_name                   = aws_s3_bucket.this.id
  }))

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.this.arn
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }


  tag_specifications {
    resource_type = "instance"

    tags = {
      "Name" = "suricata",
      "tier" = "ips" 
    }
  }


}

################################################################################
# EC2 Instance Profile
################################################################################

resource "aws_iam_role" "suricata" {
  name = format("%s-%s", var.application_name, "suricata")

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

resource "aws_iam_instance_profile" "suricata" {
  name = format("%s-%s", aws_iam_role.suricata.name, "ip")
  role = aws_iam_role.suricata.name
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.suricata.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "efs_access" {
  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]

    resources = [
      aws_efs_file_system.this.arn
    ]
  }
}

resource "aws_iam_policy" "efs_access" {
  name   = "efs-access"
  policy = data.aws_iam_policy_document.efs_access.json
}

resource "aws_iam_role_policy_attachment" "efs_access" {
  role       = aws_iam_role.suricata.name
  policy_arn = aws_iam_policy.efs_access.arn
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_access" {
  name   = "s3-access"
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.suricata.name
  policy_arn = aws_iam_policy.s3_access.arn
}

data "aws_iam_policy_document" "cw_access" {
  statement {
    actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
    ]

    resources = [
        "${aws_cloudwatch_log_group.suricata_log.arn}:*",
        "${aws_cloudwatch_log_group.fast_log.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "cw_access" {
  name   = "cw-access"
  policy = data.aws_iam_policy_document.cw_access.json
}

resource "aws_iam_role_policy_attachment" "cw_access" {
  role       = aws_iam_role.suricata.name
  policy_arn = aws_iam_policy.cw_access.arn
}

data "aws_iam_policy_document" "kms_access" {
  statement {
    actions = [
      "kms:DescribeKey",
      "kms:Decrypt"
    ]

    resources = [
        aws_kms_key.this.arn
    ]
  }
}

resource "aws_iam_policy" "kms_access" {
  name   = "kms-access"
  policy = data.aws_iam_policy_document.kms_access.json
}

resource "aws_iam_role_policy_attachment" "kms_access" {
  role       = aws_iam_role.suricata.name
  policy_arn = aws_iam_policy.kms_access.arn
}

data "aws_iam_policy_document" "vpc_access" {
  statement {
    actions = [
      "ec2:DescribeNetworkInterfaces"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "vpc_access" {
  name   = "vpc-access"
  policy = data.aws_iam_policy_document.vpc_access.json
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.suricata.name
  policy_arn = aws_iam_policy.vpc_access.arn
}

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
# Suricata LAN ENI Security Group
################################################################################

resource "aws_security_group" "suricata" {
  name   = format("%s-%s", var.application_name, "suricata")
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "suricata_ingress" {
  security_group_id = aws_security_group.suricata.id

  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = local.private_subnet_cidrs
}

resource "aws_security_group_rule" "suricata_egress" {
  security_group_id = aws_security_group.suricata.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}