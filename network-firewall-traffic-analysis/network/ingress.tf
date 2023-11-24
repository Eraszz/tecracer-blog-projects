module "ingress" {
  source = "../modules/vpc"

  name               = "central-ingress"
  cidr_block         = var.ingress_vpc_cidr_range
  availability_zones = var.ingress_vpc_availability_zones
  public_subnets     = var.ingress_vpc_public_subnets
  tgw_subnets        = var.ingress_vpc_tgw_subnets

  tgw_custom_routes = [{
    destination_cidr_block = "10.0.0.0/8"
    transit_gateway_id     = aws_ec2_transit_gateway.this.id
  }]

  public_custom_routes = [{
    destination_cidr_block = "10.0.0.0/8"
    transit_gateway_id     = aws_ec2_transit_gateway.this.id
  }]
}


################################################################################
# ALB
################################################################################

resource "aws_lb" "ingress" {
  name = format("%s-%s", substr(var.application_name, 0, 16), "ingress")

  load_balancer_type = "application"
  security_groups    = [aws_security_group.ingress.id]
  subnets            = module.ingress.public_subnet_id_list
}


################################################################################
# ALB security group
################################################################################

resource "aws_security_group" "ingress" {
  name   = format("%s-%s", var.application_name, "ingress")
  vpc_id = module.ingress.id
}

resource "aws_security_group_rule" "alb_ingress" {
  security_group_id = aws_security_group.ingress.id

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_egress" {
  security_group_id = aws_security_group.ingress.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}


################################################################################
# ALB http listener
################################################################################

resource "aws_lb_listener" "ingress" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }
}


################################################################################
# ALB target group
################################################################################

resource "aws_lb_target_group" "ingress" {
  name        = format("%s-%s", substr(var.application_name, 0, 16), "ingress")
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.ingress.id

  health_check {
    path = "/"
  }
}


resource "aws_lb_target_group_attachment" "ingress" {
  for_each = module.workload.private_subnet_id_map

  target_group_arn = aws_lb_target_group.ingress.arn
  target_id        = local.nlb_private_ipv4_addresses_list[index(keys(module.workload.private_subnet_id_map), each.key)]
  port             = 80

  availability_zone = "all"
}
