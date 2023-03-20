
################################################################################
# Set up GitHub Repository
################################################################################

resource "github_repository" "this" {
  name        = var.repository_name

  auto_init = true
  visibility  = "private"
}

resource "github_actions_secret" "this" {
  repository       = github_repository.this.name
  secret_name      = "DEPLOYMENT_IAM_ROLE_ARN"
  plaintext_value  = aws_iam_role.this.arn
}

resource "github_repository_file" "deployment_yml" {
  repository          = github_repository.this.name
  branch              = "main"
  file                = ".github/workflows/deployment.yml"
  content             = file("${path.module}/github-content/deployment.yml")
  overwrite_on_create = true
}


################################################################################
# Create Dev Branch
################################################################################

resource "github_branch" "dev" {
  repository    = github_repository.this.name
  branch        = "dev"
  source_branch = "main"

  depends_on = [
    github_repository_file.deployment_yml
  ]
}

resource "github_repository_file" "sample_tf_config" {
  repository          = github_repository.this.name
  branch              = github_branch.dev.branch
  file                = "main.tf"
  content             = file("${path.module}/github-content/main.tf")
  overwrite_on_create = true
}

