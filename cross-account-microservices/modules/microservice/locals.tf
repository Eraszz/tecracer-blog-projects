locals {

  private_subnet_ids   = [for k, v in aws_subnet.private : v.id]
  private_subnet_cidrs = [for k, v in aws_subnet.private : v.cidr_block]

  api_gateway_vpc_endpoint_id = nonsensitive(data.aws_secretsmanager_secret_version.this.secret_string)

  request_handler = toset(["get-order", "get-orders", "post-order"])
}
