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

variable "jenkins_controller_identifier" {
  description = "Name of the jenkins controller"
  type        = string
}

variable "jenkins_agent_port" {
  description = "Port Jenkins agent uses to connect to controller"
  type        = number
}

variable "jenkins_controller_port" {
  description = "Port used to connect to Jenkins controller"
  type        = number
}