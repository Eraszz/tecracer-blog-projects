variable "application_name" {
  description = "Name of the application."
  type        = string
}

variable "instance_type" {
  description = "Type of the Ec2 instance."
  type        = string
}

variable "ami_id" {
  description = "ID of the AMI."
  type        = string
}

variable "sns_topic_name" {
  description = "Name of the SNS topic to send scan results to."
  type        = string
}
