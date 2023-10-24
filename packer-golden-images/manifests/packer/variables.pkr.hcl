variable "instance_type" {
  type        = string
  description = "Instance type of the Packer image."
}

variable "region" {
  type        = string
  description = "AWS region where the Packer image should be created."
}

variable "source_ami_name" {
  type        = string
  description = "Name of the source AMI."
}

variable "source_ami_owner" {
  type        = string
  description = "Owner of the source AMI."
}

variable "packer_image_ssh_username" {
  type        = string
  description = "SSH username of the Packer Image."
}

variable "packer_image_name" {
  type        = string
  description = "Name of the Packer Image."
}
