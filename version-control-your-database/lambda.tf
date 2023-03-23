################################################################################
# Lambda Flyway Trigger
################################################################################

resource "aws_lambda_function" "flyway_trigger" {
  function_name = "flyway-trigger"
  role          = aws_iam_role.flyway_trigger.arn

  filename         = data.archive_file.flyway_trigger.output_path
  handler          = "index.lambda_handler"
  source_code_hash = data.archive_file.flyway_trigger.output_base64sha256

  environment {
    variables = {
      INSTANCE_ID               = aws_instance.flyway_host.id
      CLOUDWATCH_LOG_GROUP_NAME = aws_cloudwatch_log_group.flyway_host.name
    }
  }

  runtime = "python3.9"

  timeout     = 15
  memory_size = 128

}


data "archive_file" "flyway_trigger" {
  type        = "zip"
  source_file = "${path.module}/src/flyway-trigger/index.py"
  output_path = "${path.module}/src/flyway-trigger/python.zip"
}


resource "aws_lambda_permission" "flyway_trigger" {
  for_each = aws_s3_bucket.this

  statement_id   = "allow-execute-from-${each.value.id}"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.flyway_trigger.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = each.value.arn
  source_account = data.aws_caller_identity.this.account_id
}


################################################################################
# IAM role for Lambda Flyway Trigger
################################################################################

resource "aws_iam_role" "flyway_trigger" {
  name = "flyway-trigger"

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

data "aws_iam_policy_document" "ssm_access" {
  statement {

    actions = [
      "ssm:GetParameter",
      "ssm:GetParametersByPath"
    ]

    resources = [
      for k, v in aws_ssm_parameter.s3_mapping : v.arn
    ]
  }
  statement {

    actions = [
      "ssm:SendCommand"
    ]

    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}::document/AWS-RunShellScript",
      aws_instance.flyway_host.arn
    ]
  }

  statement {

    actions = [
      "ssm:GetCommandInvocation"
    ]

    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.this.account_id}:*"
    ]
  }
}

resource "aws_iam_policy" "ssm_access" {
  name   = "ssm-access"
  policy = data.aws_iam_policy_document.ssm_access.json
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.flyway_trigger.name
  policy_arn = aws_iam_policy.ssm_access.arn
}

resource "aws_iam_role_policy_attachment" "basic_execution_role" {
  role       = aws_iam_role.flyway_trigger.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

