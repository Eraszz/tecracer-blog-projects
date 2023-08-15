variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "aws_site_client_ip" {
  description = "IP addresse of the client EC2"
  type        = string
}

variable "on_premises_network" {
  description = "Object of On-Premises network"
  type = object({
    domain_name   = string
    cidr_range    = string
    dns_server_ip = string
  })
}
