vpc_cidr_block = "192.168.0.0/16"

public_subnets = {
  subnet_1 = {
    cidr_block        = "192.168.0.0/24"
    availability_zone = "eu-central-1a"
  }
  subnet_2 = {
    cidr_block        = "192.168.1.0/24"
    availability_zone = "eu-central-1b"
  }
}

private_subnets = {
  subnet_1 = {
    cidr_block        = "192.168.2.0/24"
    availability_zone = "eu-central-1a"
  }
  subnet_2 = {
    cidr_block        = "192.168.3.0/24"
    availability_zone = "eu-central-1b"
  }
}

application_name          = "serverless-jenkins-on-ecs"
jenkins_master_identifier = "jenkins-master"
jenkins_agent_port        = 50000
jenkins_master_port       = 8080