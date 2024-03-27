locals {
  awslogs_stream_prefix = "httpd"
}

################################################################################
# ECS cluster
################################################################################

resource "aws_ecs_cluster" "this" {
  name = var.application_name
}


################################################################################
# ECS task
################################################################################

resource "aws_ecs_task_definition" "this" {
  family = var.application_name
  container_definitions = templatefile("${path.module}/src/container_definition.tftpl", {
    container_name        = var.application_name
    container_image       = var.container_image
    container_port        = var.container_port
    awslogs_group         = aws_cloudwatch_log_group.ecs.name,
    awslogs_region        = data.aws_region.current.name,
    awslogs_stream_prefix = local.awslogs_stream_prefix
    }
  )


  network_mode = "awsvpc"
  cpu          = var.container_cpu
  memory       = var.container_memory

  execution_role_arn = aws_iam_role.ecs_execution.arn

  requires_compatibilities = ["FARGATE"]
}


################################################################################
# ECS execution role
################################################################################

resource "aws_iam_role" "ecs_execution" {
  name = "ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_basic_execution_role" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

################################################################################
# ECS service
################################################################################

resource "aws_ecs_service" "this" {
  name            = var.application_name
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue_green_1.arn
    container_name   = var.application_name
    container_port   = var.container_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }
}


################################################################################
# ECS security group for Jenkins controller
################################################################################

resource "aws_security_group" "ecs" {
  name   = format("%s-%s", var.application_name, "ecs-service")
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "ecs_ingress" {
  security_group_id = aws_security_group.ecs.id

  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "ecs_all_egress" {
  security_group_id = aws_security_group.ecs.id

  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

################################################################################
# ECS CloudWatch Logs group
################################################################################

resource "aws_cloudwatch_log_group" "ecs" {
  name              = var.application_name
  retention_in_days = 30
}