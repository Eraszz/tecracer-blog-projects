################################################################################
# Lambda Kafka Consumer
################################################################################

resource "aws_lambda_function" "this" {
  function_name = var.application_name
  role          = aws_iam_role.lambda.arn

  s3_bucket        = aws_s3_bucket.this.id
  s3_key           = aws_s3_object.this.key
  handler          = "producer.LambdaHandler"
  runtime          = "java21"
  source_code_hash = base64sha256(filebase64("${path.module}/code/target/producer-1.0.jar"))

  environment {
    variables = {
      BOOTSTRAP_SERVERS_CONFIG = aws_msk_cluster.this.bootstrap_brokers_tls
      TOPIC                    = var.kafka_topic_name
      REGISTRY_NAME            = aws_glue_registry.this.registry_name
      SCHEMA_NAME              = var.schema_name
      SCHEMA_PATHNAME          = var.schema_pathname
      DEVICE_ID                = "000001"
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.lambda.id]
    subnet_ids         = local.private_subnet_ids
  }

  timeout     = 20
  memory_size = 512
}

################################################################################
# Cloudwatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.application_name}"
  retention_in_days = 30
}


################################################################################
# Lambda Role
################################################################################

resource "aws_iam_role" "lambda" {
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


data "aws_iam_policy_document" "log_access" {
  statement {

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.lambda.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "log_access" {
  name   = format("%s-%s-%s", var.application_name, "lambda", "log-access")
  policy = data.aws_iam_policy_document.log_access.json
}

resource "aws_iam_role_policy_attachment" "log_access" {
  role       = aws_iam_role.lambda.name
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
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.ec2_access.arn
}


data "aws_iam_policy_document" "glue_access" {
  statement {
    actions = [
      "glue:GetRegistry",
      "glue:ListRegistries",
      "glue:CreateSchema",
      "glue:UpdateSchema",
      "glue:DeleteSchema",
      "glue:GetSchema",
      "glue:ListSchemas",
      "glue:RegisterSchemaVersion",
      "glue:DeleteSchemaVersions",
      "glue:GetSchemaByDefinition",
      "glue:GetSchemaVersion",
      "glue:GetSchemaVersionsDiff",
      "glue:ListSchemaVersions",
      "glue:CheckSchemaVersionValidity",
      "glue:PutSchemaVersionMetadata",
      "glue:RemoveSchemaVersionMetadata",
      "glue:QuerySchemaVersionMetadata",
      "glue:GetTags",
      "glue:TagResource",
      "glue:UnTagResource"
    ]
    resources = [
      aws_glue_registry.this.arn,
      format("arn:aws:glue:%s:%s:schema/%s/*",
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
      aws_glue_registry.this.registry_name)
    ]
  }
}

resource "aws_iam_policy" "glue_access" {
  name   = format("%s-%s-%s", var.application_name, "lambda", "glue-access")
  policy = data.aws_iam_policy_document.glue_access.json
}

resource "aws_iam_role_policy_attachment" "glue_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.glue_access.arn
}


################################################################################
# Lambda Security Group
################################################################################

resource "aws_security_group" "lambda" {
  name   = format("%s-%s", var.application_name, "lambda")
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "lambda_egress" {
  security_group_id = aws_security_group.lambda.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}