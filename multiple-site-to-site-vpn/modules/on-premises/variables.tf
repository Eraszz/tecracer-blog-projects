variable "vpc_cidr_block" {
  description = "CIDR of vpc"
  type        = string
}

variable "availability_zones" {
  description = "AZ to deploy network to"
  type        = list(string)
  default     = ["eu-central-1a"]
}

variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "aws_cidr_range" {
  description = "CIDR range of the AWS network"
  type        = string
}

variable "opposite_on_premises_cidr_range" {
  description = "CIDR range of the opposite On-Premises network"
  type        = string
}

variable "aws_peer_ips" {
  description = "IP used for the AWS VPN Peer"
  type        = list(string)
}

variable "on_premises_peer_ip" {
  description = "IP used for the On Premises VPN Peer"
  type        = string
}