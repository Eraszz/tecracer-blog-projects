variable "on_premises_networks" {
  description = "Input for On-Premises Terraform module"
  type = map(object({
    vpc_cidr_block                  = string
    opposite_on_premises_cidr_range = string
    aws_peer_ips                    = list(string)
    on_premises_peer_ip             = string
    })
  )
}

variable "aws_cidr_range" {
  description = "CIDR range of the AWS network"
  type        = string
}
