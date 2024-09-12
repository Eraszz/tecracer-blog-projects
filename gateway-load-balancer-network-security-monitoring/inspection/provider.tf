terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.66.0"
    }

    opensearch = {
      source  = "opensearch-project/opensearch"
      version = ">= 2.3.0"
    }
  }
}

provider "aws" {
}

provider "opensearch" {
  url               = format("https://%s", aws_opensearch_domain.this.endpoint)
  password          = random_password.opensearch.result
  username          = "admin"
  aws_region        = data.aws_region.current.name
  sign_aws_requests = false
  healthcheck       = false
}

