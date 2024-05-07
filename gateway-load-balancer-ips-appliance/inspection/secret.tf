################################################################################
# Secrets Manager Secret
################################################################################

resource "aws_secretsmanager_secret" "this" {
  name       = var.application_name
  kms_key_id = aws_kms_key.this.id
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    service_name = aws_vpc_endpoint_service.this.service_name,
    service_type = aws_vpc_endpoint_service.this.service_type
    }
  )
}


################################################################################
# Secret Policy
################################################################################

resource "aws_secretsmanager_secret_policy" "this" {
  secret_arn = aws_secretsmanager_secret.this.arn
  policy     = data.aws_iam_policy_document.secret.json
}

data "aws_iam_policy_document" "secret" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.allowed_service_principal_arns
    }

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy"
    ]
    resources = [aws_secretsmanager_secret.this.arn]
  }
}