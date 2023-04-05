variable "vpc_cidr_block" {
  description = "CIDR of vpc"
  type        = string
  default     = "192.168.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets that should be created"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {
    subnet_1 = {
      cidr_block        = "192.168.0.0/24"
      availability_zone = "eu-central-1a"
    }
    subnet_2 = {
      cidr_block        = "192.168.1.0/24"
      availability_zone = "eu-central-1b"
    }
  }
}

variable "private_subnets" {
  description = "Map of private subnets that should be created"
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {
    subnet_1 = {
      cidr_block        = "192.168.2.0/24"
      availability_zone = "eu-central-1a"
    }
    subnet_2 = {
      cidr_block        = "192.168.3.0/24"
      availability_zone = "eu-central-1b"
    }
  }
}

variable "application_name" {
  description = "Name of the application"
  type        = string
  default     = "jenkins-agents-on-ecs"
}

variable "jenkins_master_identifier" {
  description = "Name of the jenkins master"
  type        = string
  default     = "jenkins-master"
}

variable "jenkins_agent_port" {
  description = "Port Jenkins agent uses to connect to master"
  type        = number
  default     = 50000
}

variable "jenkins_master_port" {
  description = "Port used to connect to Jenkins master"
  type        = number
  default     = 8080
}