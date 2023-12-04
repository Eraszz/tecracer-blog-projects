################################################################################
# S3 Bucket
################################################################################

resource "aws_s3_bucket" "this" {
  bucket_prefix = substr(var.application_name, 0, 36)
  force_destroy = true
}

resource "aws_s3_object" "this" {
  bucket = aws_s3_bucket.this.id
  key    = format("%s", var.application_name)
  source = "${path.module}/code/target/producer-1.0.jar"

  source_hash = filemd5("${path.module}/code/target/producer-1.0.jar")
}