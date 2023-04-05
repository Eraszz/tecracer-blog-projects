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
  container_definitions = templatefile("${path.module}/container_definition.json", {
    container_name   = var.jenkins_master_identifier,
    container_image  = "${data.aws_caller_identity.this.account_id}.dkr.ecr.eu-central-1.amazonaws.com/container-assets:jenkins-master",
    jenkins_master_port = var.jenkins_master_port
    jenkins_agent_port = var.jenkins_agent_port
    source_volume    = "home",
    awslogs_group    = aws_cloudwatch_log_group.this.name,
    awslogs_region   = data.aws_region.current.name,

    user_name = "admin",
    user_password = "admin",
    ecs_cluster_arn = aws_ecs_cluster.this.arn,
    ecs_cluster_name = aws_ecs_cluster.this.name,
    ecs_region = data.aws_region.current.name,
    jenkins_url = "http://${aws_lb.this.dns_name}",
    jenkins_master_agent_tunnel = "${var.jenkins_master_identifier}.${var.application_name}:${var.jenkins_agent_port}",
    ecs_execution_role_arn = aws_iam_role.execution.arn,
    ecs_agent_task_role_arn = aws_iam_role.agent.arn,
    jenkins_agent_image = "${data.aws_caller_identity.this.account_id}.dkr.ecr.eu-central-1.amazonaws.com/container-assets:jenkins-agent",
    jenkins_agent_security_group = aws_security_group.ecs_jenkins_agent.id,
    jenkins_agent_subnet_ids = join(",", local.private_subnet_ids),
    }
  )


  network_mode = "awsvpc"
  cpu          = 1024
  memory       = 2048

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn

  requires_compatibilities = ["FARGATE"]


  volume {
    name = "home"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.this.id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = aws_efs_access_point.this.id
        iam             = "ENABLED"
      }
    }
  }
}


################################################################################
# ECS execution role
################################################################################

resource "aws_iam_role" "execution" {
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

resource "aws_iam_role_policy_attachment" "basic_execution_role" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


################################################################################
# ECS task role
################################################################################

resource "aws_iam_role" "task" {
  name = "ecs-task"

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

data "aws_iam_policy_document" "efs_access" {
  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]

    resources = [
      aws_efs_file_system.this.arn
    ]
  }
}

resource "aws_iam_policy" "efs_access" {
  name   = "efs-access"
  policy = data.aws_iam_policy_document.efs_access.json
}

resource "aws_iam_role_policy_attachment" "efs_access" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.efs_access.arn
}

data "aws_iam_policy_document" "ecs_access" {
  statement {
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:ListClusters",
      "ecs:ListTaskDefinitions",
      "ecs:DescribeContainerInstances",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeClusters",
      "ecs:ListTagsForResource"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ecs:ListContainerInstances"
    ]
    resources = [
      aws_ecs_cluster.this.arn
    ]
  }

  statement {
    actions = [
      "ecs:RunTask",
      "ecs:StopTask",
      "ecs:DescribeTasks"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"

      values = [
        aws_ecs_cluster.this.arn
      ]
    }
  }
}

resource "aws_iam_policy" "ecs_access" {
  name   = "ecs-access"
  policy = data.aws_iam_policy_document.ecs_access.json
}

resource "aws_iam_role_policy_attachment" "ecs_access" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.ecs_access.arn
}

data "aws_iam_policy_document" "iam_access" {
  statement {
    actions = [
      "iam:GetRole",
      "iam:PassRole"
    ]

    resources = [
      aws_iam_role.execution.arn,
      aws_iam_role.agent.arn
    ]
  }
}

resource "aws_iam_policy" "iam_access" {
  name   = "iam-access"
  policy = data.aws_iam_policy_document.iam_access.json
}

resource "aws_iam_role_policy_attachment" "iam_access" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.iam_access.arn
}


################################################################################
# ECS agent role
################################################################################

resource "aws_iam_role" "agent" {
  name = "ecs-agent"

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

resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.agent.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
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
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.jenkins_master_identifier
    container_port   = var.jenkins_master_port
  }

  service_registries {
    registry_arn = aws_service_discovery_service.this.arn
    port         = var.jenkins_agent_port
  }
}


################################################################################
# ECS security group for Jenkins master
################################################################################

resource "aws_security_group" "ecs_service" {
  name   = "ecs-jenkins-master"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "alb_ingress" {
  security_group_id = aws_security_group.ecs_service.id

  type                     = "ingress"
  from_port                = var.jenkins_master_port
  to_port                  = var.jenkins_master_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "service_all_egress" {
  security_group_id = aws_security_group.ecs_service.id

  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "jenkins_agent_ingress" {
  security_group_id = aws_security_group.ecs_service.id

  type                     = "ingress"
  from_port                = var.jenkins_agent_port
  to_port                  = var.jenkins_agent_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_jenkins_agent.id
}

################################################################################
# ECS security group for Jenkins agents
################################################################################

resource "aws_security_group" "ecs_jenkins_agent" {
  name   = "ecs-jenkins-agents"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "agent_all_egress" {
  security_group_id = aws_security_group.ecs_jenkins_agent.id

  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

################################################################################
# ECS CloudWatch Logs group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = var.application_name
  retention_in_days = 30
}