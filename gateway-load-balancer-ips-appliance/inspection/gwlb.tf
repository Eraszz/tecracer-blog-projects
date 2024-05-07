################################################################################
# GLWB
################################################################################

resource "aws_lb" "this" {
  name = var.application_name

  internal                         = false
  load_balancer_type               = "gateway"
  subnets                          = local.private_subnet_ids
  enable_cross_zone_load_balancing = true
}


################################################################################
# GLWB listener
################################################################################

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}


################################################################################
# GLWB target group
################################################################################

resource "aws_lb_target_group" "this" {
  name                 = var.application_name
  port                 = 6081
  protocol             = "GENEVE"
  target_type          = "instance"
  vpc_id               = aws_vpc.this.id
  deregistration_delay = 30

  health_check {
    port     = 80
    protocol = "HTTP"
  }
}