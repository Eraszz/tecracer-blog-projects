################################################################################
# CodeCommit Repository
################################################################################

resource "aws_codecommit_repository" "this" {
  repository_name = var.application_name
}