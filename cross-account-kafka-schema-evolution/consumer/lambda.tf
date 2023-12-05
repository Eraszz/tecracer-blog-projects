################################################################################
# Lambda Kafka Consumer
################################################################################

resource "aws_lambda_function" "this" {
  function_name = var.application_name
  role          = aws_iam_role.this.arn

  s3_bucket        = aws_s3_bucket.this.id
  s3_key           = aws_s3_object.this.key
  handler          = "consumer.LambdaHandler"
  runtime          = "java21"
  source_code_hash = base64encode("${path.module}/code/target/consumer-1.0.jar")

  environment {
    variables = {
      REGISTRY_NAME = var.glue_schema_registry_name
      ROLE_ARN = var.cross_account_glue_access_role
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.this.id]
    subnet_ids         = local.private_subnet_ids
  }

  timeout     = 20
  memory_size = 512
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
  name = format("%s-%s", var.application_name, "lambda")

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

data "aws_iam_policy_document" "iam_access" {
  statement {

    actions = [
      "sts:AssumeRole"
    ]

    resources = [
      var.cross_account_glue_access_role
    ]
  }
}

resource "aws_iam_policy" "iam_access" {
  name   = format("%s-%s-%s", var.application_name, "lambda", "iam-access")
  policy = data.aws_iam_policy_document.iam_access.json
}

resource "aws_iam_role_policy_attachment" "iam_access" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.iam_access.arn
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
  name   = format("%s-%s-%s", var.application_name, "lambda", "log-access")
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
  name   = format("%s-%s-%s", var.application_name, "lambda", "ec2-access")
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
  name   = format("%s-%s-%s", var.application_name, "lambda", "dynamodb-access")
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

  topics            = [var.kafka_topic_name]
  starting_position = "TRIM_HORIZON"


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
