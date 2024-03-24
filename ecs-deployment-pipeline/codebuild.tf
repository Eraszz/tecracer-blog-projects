################################################################################
# CodeBuild Project (Build Docker)
################################################################################

resource "aws_codebuild_project" "build" {
  name                   = format("%s-%s", "build", var.application_name)
  service_role           = aws_iam_role.codebuild.arn
  concurrent_build_limit = 1

  environment {
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:7.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/files/buildspec.yaml")
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.build.name
      status     = "ENABLED"
    }
  }
}


################################################################################
# Cloudwatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "build" {
  name = "/aws/codebuild/${var.application_name}-build"

  retention_in_days = 30
}


################################################################################
# IAM Role for CodeBuild
################################################################################

resource "aws_iam_role" "codebuild" {
  name = format("%s-%s", var.application_name, "codebuild")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "codebuild" {
  statement {

    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]

    resources = [aws_ecr_repository.this.arn]
  }

  statement {

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["${aws_cloudwatch_log_group.build.arn}:*"]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.artifacts.arn, "${aws_s3_bucket.artifacts.arn}/*"]
  }

  statement {
    sid = "kmsaccess"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.this.arn]
  }
}

resource "aws_iam_policy" "codebuild" {
  name   = format("%s-%s-%s", var.application_name, "codebuild", "build")
  policy = data.aws_iam_policy_document.codebuild.json
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}