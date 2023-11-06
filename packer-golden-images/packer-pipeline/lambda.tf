################################################################################
# Lambda to store Inspector findings
################################################################################

resource "aws_lambda_function" "export_findings" {
  function_name = format("%s-%s", var.application_name, "export-findings")
  role          = aws_iam_role.export_findings.arn

  filename         = data.archive_file.export_findings.output_path
  handler          = "index.lambda_handler"
  source_code_hash = data.archive_file.export_findings.output_base64sha256

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.inspector.id
      KMS_KEY_ARN    = aws_kms_key.this.arn
    }
  }

  runtime = "python3.10"

  timeout     = 15
  memory_size = 128

}


data "archive_file" "export_findings" {
  type        = "zip"
  source_file = "${path.module}/src/index.py"
  output_path = "${path.module}/src/python.zip"
}


resource "aws_lambda_permission" "export_findings" {
  statement_id   = "allow-execute-from-eventbridge"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.export_findings.function_name
  principal      = "events.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}


################################################################################
# IAM role for Lambda Flyway Trigger
################################################################################

resource "aws_iam_role" "export_findings" {
  name = format("%s-%s", var.application_name, "export-findings")

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

data "aws_iam_policy_document" "export_findings" {
  statement {

    actions = [
      "inspector2:ListFindings",
      "inspector2:CreateFindingsReport"
    ]

    resources = ["*"]
  }

  statement {

    actions = [
      "s3:CreateBucket",
      "s3:DeleteObject",
      "s3:PutBucketAcl",
      "s3:PutBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [aws_s3_bucket.inspector.arn, "${aws_s3_bucket.inspector.arn}/*"]
  }
}

resource "aws_iam_policy" "export_findings" {
  name   = format("%s-%s", var.application_name, "export-findings")
  policy = data.aws_iam_policy_document.export_findings.json
}

resource "aws_iam_role_policy_attachment" "export_findings" {
  role       = aws_iam_role.export_findings.name
  policy_arn = aws_iam_policy.export_findings.arn
}

resource "aws_iam_role_policy_attachment" "basic_execution_role" {
  role       = aws_iam_role.export_findings.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

