################################################################################
# Lambda Kafka Consumer
################################################################################

resource "aws_lambda_function" "this" {
  function_name = var.application_name
  role          = aws_iam_role.this.arn

  filename         = data.archive_file.this.output_path
  handler          = "index.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.this.output_base64sha256

  environment {
    variables = {
      KAFKA_TOPIC         = "${var.application_name}-0"
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.this.name
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.this.id]
    subnet_ids         = local.private_subnet_ids
  }

  timeout     = 10
  memory_size = 512
}

data "archive_file" "this" {
  type        = "zip"
  source_file = "${path.module}/src/index.py"
  output_path = "${path.module}/src/python.zip"
}


################################################################################
# Cloudwatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.application_name}"
  retention_in_days = 30
}


################################################################################
# Lambda Role
################################################################################

resource "aws_iam_role" "this" {
  name = "${var.application_name}-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}


data "aws_iam_policy_document" "log_access" {
  statement {

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.this.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "log_access" {
  name   = "log-access"
  policy = data.aws_iam_policy_document.log_access.json
}

resource "aws_iam_role_policy_attachment" "log_access" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.log_access.arn
}


data "aws_iam_policy_document" "ec2_access" {
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVpcs",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "ec2_access" {
  name   = "ec2-access"
  policy = data.aws_iam_policy_document.ec2_access.json
}

resource "aws_iam_role_policy_attachment" "ec2_access" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ec2_access.arn
}


data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:BatchWriteItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem"
    ]
    resources = [
      aws_dynamodb_table.this.arn
    ]
  }
}

resource "aws_iam_policy" "dynamodb_access" {
  name   = "dynamodb-access"
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}


################################################################################
# Lambda Event Source Mapping
################################################################################

resource "aws_lambda_event_source_mapping" "this" {

  function_name = aws_lambda_function.this.function_name

  topics            = [var.application_name]
  starting_position = "LATEST"


  self_managed_event_source {
    endpoints = {
      KAFKA_BOOTSTRAP_SERVERS = local.bootstrap_brokers_tls
    }
  }

  dynamic "source_access_configuration" {
    for_each = concat(local.event_source_mapping_subnet_list, local.event_source_mapping_security_group_list)

    content {
      type = source_access_configuration.value.type
      uri  = source_access_configuration.value.uri
    }
  }

  batch_size = 10
}