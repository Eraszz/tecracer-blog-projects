################################################################################
# Get Current AWS Account ID and Region
################################################################################

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}