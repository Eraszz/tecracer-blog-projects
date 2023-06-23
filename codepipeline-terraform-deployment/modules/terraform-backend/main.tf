##################################################
# S3
##################################################  

resource "aws_s3_bucket" "this" {
  bucket_prefix = var.tf_state_storage_bucket_name
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = "true"
  block_public_policy     = "true"
  ignore_public_acls      = "true"
  restrict_public_buckets = "true"

}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

data "aws_iam_policy_document" "bucket_policy" {

  statement {
    sid    = "EnforceUseOfKMSEncryption"
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.this.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotEqualsIfExists"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "aws:kms"
      ]
    }
    condition {
      test     = "StringNotEqualsIfExists"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"

      values = [
        aws_kms_key.this.arn
      ]
    }
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "false"
      ]
    }
  }
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.this.arn,
    "${aws_s3_bucket.this.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = [
        "false"
      ]
    }
  }
}


##################################################
# KMS
##################################################

resource "aws_kms_key" "this" {
  description             = "KMS key for encrption of CloudTrail logs in CW and S3"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 30
  is_enabled              = true
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.key_policy.json
}

resource "aws_kms_alias" "this" {
  name          = format("alias/%s", var.aws_kms_alias)
  target_key_id = aws_kms_key.this.key_id
}

data "aws_iam_policy_document" "key_policy" {

  statement {
    sid    = "Enable IAM Root User Permissions"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = [
        format("arn:aws:iam::%s:root", var.aws_account_id)
      ]
    }
  }
}

##################################################
# DynamoDB
##################################################

resource "aws_dynamodb_table" "this" {
  name         = var.tf_state_storage_dynamodb_lock_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  point_in_time_recovery {
    enabled = true
  }
}