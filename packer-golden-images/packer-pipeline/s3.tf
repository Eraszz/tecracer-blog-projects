################################################################################
# S3 Bucket for Codepipeline
################################################################################

resource "aws_s3_bucket" "codepipeline" {
  bucket_prefix = format("%s-%s", var.application_name, "artifacts")

  force_destroy = true
}


################################################################################
# S3 Bucket policy
################################################################################

resource "aws_s3_bucket_policy" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id

  policy = data.aws_iam_policy_document.s3_codepipeline.json
}


################################################################################
# S3 Bucket server side encryption Configuration
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.arn
      sse_algorithm     = "aws:kms"
    }
  }
}


################################################################################
# S3 Policies
################################################################################

data "aws_iam_policy_document" "s3_codepipeline" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [aws_s3_bucket.codepipeline.arn, "${aws_s3_bucket.codepipeline.arn}/*"]

    condition {
      test     = "ArnEquals"
      variable = "AWS:SourceArn"
      values = [
        aws_codepipeline.this.arn,
        aws_codebuild_project.build.arn,
        aws_codebuild_project.share.arn
      ]
    }
  }
}


################################################################################
# S3 Bucket for Inspector export
################################################################################

resource "aws_s3_bucket" "inspector" {
  bucket_prefix = format("%s-%s", var.application_name, "inspector")

  force_destroy = true
}


################################################################################
# S3 Bucket policy for Inspector export
################################################################################

resource "aws_s3_bucket_policy" "inspector" {
  bucket = aws_s3_bucket.inspector.id

  policy = data.aws_iam_policy_document.inspector.json
}


################################################################################
# S3 Bucket server side encryption Configuration for Inspector export
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "inspector" {
  bucket = aws_s3_bucket.inspector.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.arn
      sse_algorithm     = "aws:kms"
    }
  }
}


################################################################################
# S3 Policies for Inspector export
################################################################################

data "aws_iam_policy_document" "inspector" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["inspector2.amazonaws.com"]
    }

    effect = "Allow"
    actions = [
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:AbortMultipartUpload"
    ]

    resources = [aws_s3_bucket.inspector.arn, "${aws_s3_bucket.inspector.arn}/*"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:inspector2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report/*",
        aws_lambda_function.export_findings.arn
      ]
    }
  }
}