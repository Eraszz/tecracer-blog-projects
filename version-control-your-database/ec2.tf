################################################################################
# Flyway EC2 Instance
################################################################################

resource "aws_instance" "flyway_host" {

  instance_type          = "t3.micro"
  ami                    = data.aws_ami.flyway_host_ami.id
  iam_instance_profile   = aws_iam_instance_profile.flyway_host.name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.aurora_mysql.id]

  user_data_base64 = base64encode(templatefile("${path.module}/src/flyway-host/setup.sh", {
    flyway_version = var.flyway_version
    flyway_conf    = var.flyway_conf
    flyway_url     = "jdbc:mysql://${aws_rds_cluster.aurora_mysql.endpoint}:${aws_rds_cluster.aurora_mysql.port}"
    flyway_db_user = var.master_username
    flyway_db_pw   = var.master_password
  }))
}

resource "aws_cloudwatch_log_group" "flyway_host" {
  name              = "/ssm/runcommand/flyway-host"
  retention_in_days = 30
}

################################################################################
# Get Latest Amazon Linux (with SSM Agent)
################################################################################

data "aws_ami" "flyway_host_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

################################################################################
# IAM instance profile for Flyway host
################################################################################

resource "aws_iam_role" "flyway_host" {
  name = "flyway-host"

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

resource "aws_iam_instance_profile" "flyway_host" {
  name = "flyway-host"
  role = aws_iam_role.flyway_host.name
}

data "aws_iam_policy_document" "cloudwatch_access" {
  statement {
    actions = [
      "logs:DescribeLogGroups"
    ]

    resources = ["*"]
  }

  statement {

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = [
      aws_cloudwatch_log_group.flyway_host.arn,
      "${aws_cloudwatch_log_group.flyway_host.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "cloudwatch_access" {
  name   = "cloudwatch-access"
  policy = data.aws_iam_policy_document.cloudwatch_access.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_access" {
  role       = aws_iam_role.flyway_host.name
  policy_arn = aws_iam_policy.cloudwatch_access.arn
}

data "aws_iam_policy_document" "s3_access" {
  dynamic "statement" {
    for_each = aws_s3_bucket.this
    content {
      actions = [
        "s3:ListBucket",
        "s3:GetObject"
      ]
      resources = [
        statement.value.arn,
        "${statement.value.arn}/*"
      ]
    }

  }
}

resource "aws_iam_policy" "s3_access" {
  name   = "s3-access"
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.flyway_host.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.flyway_host.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}