################################################################################
# Cross Account Lambda Role
################################################################################

resource "aws_iam_role" "cross_account_glue_access" {
  name = format("%s-%s", var.application_name, "cross-account")

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.allowed_service_principal_arns
    }
  }
}

data "aws_iam_policy_document" "cross_account_glue_access" {
  statement {
    actions = [
      "glue:GetRegistry",
      "glue:ListRegistries",
      "glue:GetSchema",
      "glue:ListSchemas",
      "glue:GetSchemaByDefinition",
      "glue:GetSchemaVersion",
      "glue:GetSchemaVersionsDiff",
      "glue:ListSchemaVersions",
      "glue:CheckSchemaVersionValidity",
      "glue:QuerySchemaVersionMetadata",
    ]
    resources = [
      aws_glue_registry.this.arn,
      format("arn:aws:glue:%s:%s:schema/%s/*",
        data.aws_region.current.name,
        data.aws_caller_identity.current.account_id,
      aws_glue_registry.this.registry_name)
    ]
  }

  statement {
    actions = [
      "glue:GetSchemaVersion"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cross_account_glue_access" {
  name   = format("%s-%s-%s", var.application_name, "cross-account", "glue-access")
  policy = data.aws_iam_policy_document.cross_account_glue_access.json
}

resource "aws_iam_role_policy_attachment" "cross_account_glue_access" {
  role       = aws_iam_role.cross_account_glue_access.name
  policy_arn = aws_iam_policy.cross_account_glue_access.arn
}