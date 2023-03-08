################################################################################
# Set required providers and version
################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.40.0"
    }
  }
  required_version = ">=1.3.0"
}

provider "aws" {
  region = var.aws_region
}
