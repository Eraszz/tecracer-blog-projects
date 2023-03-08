################################################################################
# IAM Role
################################################################################

resource "aws_iam_role" "this" {
  name = var.name
  assume_role_policy   = data.aws_iam_policy_document.this.json
}


data "aws_iam_policy_document" "this" {
  dynamic "statement" {
    for_each = var.principal

    content {
      actions = var.actions
      effect  = "Allow"

      principals {
        type        = statement.key
        identifiers = statement.value
      }

      dynamic "condition" {
        for_each = var.conditions

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}


################################################################################
# IAM Policies
################################################################################

resource "aws_iam_policy" "this" {
  for_each = var.policy_document

  name   = "${var.name}-${each.key}"
  policy = each.value
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = aws_iam_policy.this

  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}
