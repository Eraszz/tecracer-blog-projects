################################################################################
# Secrets Manager Secret (GWLB)
################################################################################

resource "aws_secretsmanager_secret" "gwlb" {
  name       = var.application_name
  kms_key_id = aws_kms_key.this.id
}

resource "aws_secretsmanager_secret_version" "gwlb" {
  secret_id = aws_secretsmanager_secret.gwlb.id
  secret_string = jsonencode({
    service_name = aws_vpc_endpoint_service.this.service_name,
    service_type = aws_vpc_endpoint_service.this.service_type
    }
  )
}


################################################################################
# Secret Policy
################################################################################

resource "aws_secretsmanager_secret_policy" "gwlb" {
  secret_arn = aws_secretsmanager_secret.gwlb.arn
  policy     = data.aws_iam_policy_document.secret_gwlb.json
}

data "aws_iam_policy_document" "secret_gwlb" {
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
    resources = [aws_secretsmanager_secret.gwlb.arn]
  }
}


################################################################################
# Secrets Manager Secret (OpenSearch)
################################################################################

resource "aws_secretsmanager_secret" "opensearch" {
  name       = format("%s-%s", var.application_name, "opensearch")
  kms_key_id = aws_kms_key.this.id
}

resource "aws_secretsmanager_secret_version" "opensearch" {
  secret_id = aws_secretsmanager_secret.opensearch.id
  secret_string = jsonencode({
    username = "admin",
    password = random_password.opensearch.result
    }
  )
}

resource "random_password" "opensearch" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}