################################################################################
# LB
################################################################################

resource "aws_lb" "this" {
  name                             = var.name
  load_balancer_type               = "network"
  internal                         = true
  subnets                          = var.subnets
  ip_address_type                  = "ipv4"
  enable_cross_zone_load_balancing = true
}

################################################################################
# LB HTTP TCP listener
################################################################################

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  protocol          = "TCP"

  port = var.port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

################################################################################
# LB target groups
################################################################################

resource "aws_lb_target_group" "this" {
  name        = var.name
  port        = var.port
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled  = true
    protocol = "TCP"
  }
}

################################################################################
# LB Target Group Attachment
################################################################################

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.target_id
  port             = var.port
}

################################################################################
# VPC Endpoint Service
################################################################################

resource "aws_vpc_endpoint_service" "this" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.this.arn]
}


################################################################################
# VPC Endpoint Service allowed principals
################################################################################

resource "aws_vpc_endpoint_service_allowed_principal" "this" {
  for_each = toset(var.allowed_service_principal_arns)

  vpc_endpoint_service_id = aws_vpc_endpoint_service.this.id
  principal_arn           = each.value
}