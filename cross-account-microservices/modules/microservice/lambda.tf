################################################################################
# Lambda Request Handler
################################################################################

resource "aws_lambda_function" "this" {
  for_each = local.request_handler

  function_name = format("%s-%s-%s", var.application_name, var.microservice_name, each.value)
  role          = aws_iam_role.this.arn

  filename         = data.archive_file.this[each.key].output_path
  handler          = "index.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.this[each.key].output_base64sha256

  timeout     = 10
  memory_size = 512

  environment {
    variables = {
      DYNAMODB_TABLE_NAME         = aws_dynamodb_table.this.name
      GLOBAL_SECONDARY_INDEX_NAME = "orderDateIndex"
      MICROSERVICE_TOPIC          = var.microservice_name
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.this.id]
    subnet_ids         = local.private_subnet_ids
  }
}

data "archive_file" "this" {
  for_each = local.request_handler

  type        = "zip"
  source_file = "${path.module}/src/${each.value}/index.py"
  output_path = "${path.module}/src/${each.value}/python.zip"
}


################################################################################
# Cloudwatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  for_each = aws_lambda_function.this

  name = "/aws/lambda/${each.value.function_name}"
}


################################################################################
# Lambda Resource Policy Permissions
################################################################################

resource "aws_lambda_permission" "this" {
  for_each = aws_lambda_function.this

  function_name = each.value.function_name

  action     = "lambda:InvokeFunction"
  principal  = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*"
}


################################################################################
# Lambda Permissions
################################################################################

resource "aws_iam_role" "this" {
  name = format("%s-%s-lambda", var.application_name, var.microservice_name)

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

data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:GetItem"
    ]
    resources = [
      aws_dynamodb_table.this.arn,
      "${aws_dynamodb_table.this.arn}/index/*"
    ]
  }
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

resource "aws_iam_policy" "dynamodb_access" {
  name   = format("%s-%s-dynamodb-access", var.application_name, var.microservice_name)
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

resource "aws_iam_policy" "ec2_access" {
  name   = format("%s-%s-ec2-access", var.application_name, var.microservice_name)
  policy = data.aws_iam_policy_document.ec2_access.json
}

resource "aws_iam_role_policy_attachment" "ec2_access" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.ec2_access.arn
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


################################################################################
# Lambda Security Group
################################################################################

resource "aws_security_group" "this" {
  name   = format("%s-%s", var.application_name, var.microservice_name)
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.this.id

  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = -1
  prefix_list_ids = [data.aws_ec2_managed_prefix_list.this.id]
}

