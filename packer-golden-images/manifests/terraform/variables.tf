variable "ami_id" {
  description = "ID of the AMI."
  type        = string
}

variable "ssm_parameter_path" {
  description = "Path to the SSM Parameter that contains the AWS Account IDs the AMI should be shared with."
  type        = string
}
