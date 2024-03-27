################################################################################
# S3 Bucket for Codepipeline Artifacts
################################################################################

resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = format("%s-%s", var.application_name, "artifacts")

  force_destroy = true
}


################################################################################
# S3 Bucket policy
################################################################################

resource "aws_s3_bucket_policy" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  policy = data.aws_iam_policy_document.artifacts.json
}


################################################################################
# S3 Bucket server side encryption Configuration
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

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

data "aws_iam_policy_document" "artifacts" {
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

    resources = [aws_s3_bucket.artifacts.arn, "${aws_s3_bucket.artifacts.arn}/*"]

    condition {
      test     = "ArnEquals"
      variable = "AWS:SourceArn"
      values = [
        aws_codepipeline.this.arn,
        aws_codebuild_project.build.arn,
        aws_codedeploy_app.this.arn
      ]
    }
  }
}


################################################################################
# S3 Bucket for Static Files (CodeDeploy)
################################################################################

resource "aws_s3_bucket" "static" {
  bucket_prefix = format("%s-%s", var.application_name, "static")

  force_destroy = true
}


################################################################################
# S3 Bucket Versioning
################################################################################

resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.id
  versioning_configuration {
    status = "Enabled"
  }
}


################################################################################
# S3 Bucket policy
################################################################################

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id

  policy = data.aws_iam_policy_document.static.json
}


################################################################################
# S3 Bucket server side encryption Configuration
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  bucket = aws_s3_bucket.static.id

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

data "aws_iam_policy_document" "static" {
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

    resources = [aws_s3_bucket.static.arn, "${aws_s3_bucket.static.arn}/*"]

    condition {
      test     = "ArnEquals"
      variable = "AWS:SourceArn"
      values = [
        aws_codepipeline.this.arn,
        aws_codedeploy_app.this.arn
      ]
    }
  }
}

################################################################################
# S3 Bucket Upload static files (appspec.yaml / taskdef.json)
################################################################################

resource "aws_s3_object" "static" {
  bucket = aws_s3_bucket.static.id
  key    = "static.zip"
  source = "${path.module}/src/static.zip"
}

# Archive multiple files and exclude file.

data "archive_file" "static" {
  type        = "zip"
  output_path = "${path.module}/src/static.zip"

  source {
    content = templatefile("${path.module}/src/appspec.yaml.tftpl", {
      container_name = var.application_name
      container_port = var.container_port
    })
    filename = "appspec.yaml"
  }

  source {
    content = templatefile("${path.module}/src/taskdef.json.tftpl", {
      container_name               = var.application_name
      container_port               = var.container_port
      container_cpu                = var.container_cpu
      container_memory             = var.container_memory
      container_execution_role_arn = aws_iam_role.ecs_execution.arn
      awslogs_group                = aws_cloudwatch_log_group.ecs.name
      awslogs_region               = data.aws_region.current.name
      awslogs_stream_prefix        = local.awslogs_stream_prefix
    })
    filename = "taskdef.json"
  }
}