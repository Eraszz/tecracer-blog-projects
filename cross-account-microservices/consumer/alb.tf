################################################################################
# ALB
################################################################################

resource "aws_lb" "this" {
  name = var.application_name

  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.private_subnet_ids
}


################################################################################
# ALB security group
################################################################################

resource "aws_security_group" "alb" {
  name   = "${var.application_name}-alb"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "alb_ingress" {
  security_group_id = aws_security_group.alb.id

  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr_block]
}

resource "aws_security_group_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id

  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoint.id
}


################################################################################
# ALB http listener
################################################################################

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.this.arn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}


################################################################################
# ALB target group
################################################################################

resource "aws_lb_target_group" "this" {
  name        = var.application_name
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  health_check {
    path = "/login"
  }
}


################################################################################
# ALB target group attachement
################################################################################

resource "aws_lb_target_group_attachment" "this" {
  count = length(aws_subnet.private)

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = data.aws_network_interface.this[count.index].private_ip
  port             = 443
}

data "aws_network_interface" "this" {
  count = length(aws_subnet.private)
  id    = tolist(aws_vpc_endpoint.this.network_interface_ids)[count.index]
}
