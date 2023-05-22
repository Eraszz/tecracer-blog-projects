################################################################################
# ECR
################################################################################

resource "aws_ecr_repository" "this" {
  name                 = var.application_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}