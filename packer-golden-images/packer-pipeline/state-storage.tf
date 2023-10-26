##################################################
# S3
##################################################  

resource "aws_s3_bucket" "state_storage" {
  bucket_prefix = var.tf_state_storage_bucket_name
}

resource "aws_s3_bucket_versioning" "state_storage" {
  bucket = aws_s3_bucket.state_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_storage" {
  bucket = aws_s3_bucket.state_storage.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state_storage.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_storage" {
  bucket = aws_s3_bucket.state_storage.id

  block_public_acls       = "true"
  block_public_policy     = "true"
  ignore_public_acls      = "true"
  restrict_public_buckets = "true"

}

resource "aws_s3_bucket_policy" "state_storage" {
  bucket = aws_s3_bucket.state_storage.id
  policy = data.aws_iam_policy_document.state_storage_s3.json
}

data "aws_iam_policy_document" "state_storage_s3" {

  statement {
    sid    = "EnforceUseOfKMSEncryption"
    effect = "Deny"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.state_storage.arn}/*"]
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
        aws_kms_key.state_storage.arn
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
      aws_s3_bucket.state_storage.arn,
    "${aws_s3_bucket.state_storage.arn}/*"]
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

resource "aws_kms_key" "state_storage" {
  description             = "KMS key for encrption of CloudTrail logs in CW and S3"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 30
  is_enabled              = true
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.state_storage_kms.json
}

resource "aws_kms_alias" "state_storage" {
  name          = format("alias/%s", var.tf_state_aws_kms_alias)
  target_key_id = aws_kms_key.state_storage.key_id
}

data "aws_iam_policy_document" "state_storage_kms" {

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
        format("arn:aws:iam::%s:root", data.aws_caller_identity.current.account_id)
      ]
    }
  }
}

##################################################
# DynamoDB
##################################################

resource "aws_dynamodb_table" "state_storage" {
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