################################################################################
# ALB
################################################################################

resource "aws_lb" "this" {
  name = var.application_name

  internal           = false
  load_balancer_type = "application"
  subnets            = local.public_subnet_ids
  security_groups = [ aws_security_group.alb.id ]
}

################################################################################
# Server Security Group
################################################################################

resource "aws_security_group" "alb" {
  name   = "${var.application_name}-alb"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "alb_http_ingress" {
  security_group_id = aws_security_group.alb.id

  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              =  ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id

  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.server.id
}

################################################################################
# ALB listener
################################################################################

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

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
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.this.id

  health_check {
    path = "/"
  }
}

################################################################################
# ALB target group attachement
################################################################################

resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.server.id
  port             = 80
}