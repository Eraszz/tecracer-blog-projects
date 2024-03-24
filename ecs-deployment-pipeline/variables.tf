variable "vpc_cidr_block" {
  description = "CIDR of vpc"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnets that should be created"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnets that should be created"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "alb_qa_port" {
  description = "Port that will be used for QA traffic"
  type        = number
}

variable "alb_prd_port" {
  description = "Port that will be used for PRD traffic"
  type        = number
}

variable "container_image" {
  description = "Image of the container to be used by ECS"
  type        = string
}

variable "container_port" {
  description = "Port on the container that should be exposed."
  type        = number
}

variable "container_cpu" {
  description = "vCPU of the FARGATE container."
  type        = number
}

variable "container_memory" {
  description = "Memory of the FARGATE container."
  type        = number
}

variable "sns_endpoint" {
  description = "Terraform version to install in CodeBuild Container"
  type        = string
}
