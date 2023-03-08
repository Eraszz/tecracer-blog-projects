################################################################################
# AWS Variables
################################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
}


################################################################################
# API Gateway Variables
################################################################################

variable "api_name" {
  description = "Name of the REST API."
  type        = string
}