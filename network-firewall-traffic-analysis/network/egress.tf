module "egress" {
  source = "../modules/vpc"

  name               = "central-egress"
  cidr_block         = var.egress_vpc_cidr_range
  availability_zones = var.egress_vpc_availability_zones
  public_subnets     = var.egress_vpc_public_subnets
  tgw_subnets        = var.egress_vpc_tgw_subnets

  create_nat_gateway = true

  tgw_custom_routes = [{
    destination_cidr_block = "10.0.0.0/8"
    transit_gateway_id     = aws_ec2_transit_gateway.this.id
  }]

  public_custom_routes = [{
    destination_cidr_block = "10.0.0.0/8"
    transit_gateway_id     = aws_ec2_transit_gateway.this.id
  }]
}