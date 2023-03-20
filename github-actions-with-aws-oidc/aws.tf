
################################################################################
# Get GitHub TLS cert
################################################################################

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}


################################################################################
# IAM OpenID Connect for GitHub
################################################################################

resource "aws_iam_openid_connect_provider" "this" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}


################################################################################
# IAM Role for GitHub
################################################################################

resource "aws_iam_role" "this" {
  name = "github-actions"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}


data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.org_or_user_name}/${var.repository_name}:pull_request",
        "repo:${var.org_or_user_name}/${var.repository_name}:ref:refs/heads/main"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role = aws_iam_role.this.name

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}