################################################################################
# Set required providers and version
################################################################################

terraform {
  backend "s3" {
    bucket         = "terraform-state-storage20231025124340206300000001"
    region         = "eu-central-1"
    key            = "terraform.tfstate"
    dynamodb_table = "terraform-state-storage"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-storage"

  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.40.0"
    }
  }
  required_version = ">=1.4.4"
}

provider "aws" {
  region = "eu-central-1"
}