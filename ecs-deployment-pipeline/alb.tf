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
  name   = format("%s-%s", var.application_name, "alb")
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "prd_ingress" {
  security_group_id = aws_security_group.alb.id

  type        = "ingress"
  from_port   = var.alb_prd_port
  to_port     = var.alb_prd_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "qa_ingress" {
  security_group_id = aws_security_group.alb.id

  type        = "ingress"
  from_port   = var.alb_qa_port
  to_port     = var.alb_qa_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ecs_egress" {
  security_group_id = aws_security_group.alb.id

  type                     = "egress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}


################################################################################
# ALB prd/qa listener
################################################################################

resource "aws_lb_listener" "prd" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.alb_prd_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue_green_1.arn
  }
}

resource "aws_lb_listener" "qa" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.alb_qa_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue_green_2.arn
  }
}


################################################################################
# ALB target group
################################################################################

resource "aws_lb_target_group" "blue_green_1" {
  name        = format("%s-%s", var.application_name, "bg-1")
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group" "blue_green_2" {
  name        = format("%s-%s", var.application_name, "bg-2")
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  health_check {
    path = "/"
  }
}
