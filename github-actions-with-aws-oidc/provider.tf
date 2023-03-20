
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.40.0"
    }
    github = {
      source  = "integrations/github"
      version = ">=5.0"
    }
  }
}

provider "github" {}

provider "aws" {}