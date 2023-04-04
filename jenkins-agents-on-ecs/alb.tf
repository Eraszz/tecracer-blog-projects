################################################################################
# ALB
################################################################################

resource "aws_lb" "this" {
  name = var.application_name

  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.public_subnet_ids
}


################################################################################
# ALB security group
################################################################################

resource "aws_security_group" "alb" {
  name   = "alb"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "http_ingress" {
  security_group_id = aws_security_group.alb.id

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ecs_egress" {
  security_group_id = aws_security_group.alb.id

  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_service.id
}


################################################################################
# ALB http listener
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
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  health_check {
    path = "/login"
  }
}
