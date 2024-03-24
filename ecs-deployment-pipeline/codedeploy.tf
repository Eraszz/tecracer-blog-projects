################################################################################
# CodeDeploy
################################################################################

resource "aws_codedeploy_app" "this" {
  name             = var.application_name
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "this" {
  deployment_group_name  = var.application_name
  app_name               = aws_codedeploy_app.this.name
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 60
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.this.name
    service_name = aws_ecs_service.this.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.prd.arn]
      }

      test_traffic_route {
        listener_arns = [aws_lb_listener.qa.arn]
      }

      target_group {
        name = aws_lb_target_group.blue_green_1.name
      }

      target_group {
        name = aws_lb_target_group.blue_green_2.name
      }
    }
  }
}


################################################################################
# IAM Role for CodeDeploy
################################################################################

resource "aws_iam_role" "codedeploy" {
  name = format("%s-%s", var.application_name, "codedeploy")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "codedeploy" {

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]

    resources = [
      aws_s3_bucket.artifacts.arn,
      "${aws_s3_bucket.artifacts.arn}/*",
      aws_s3_bucket.static.arn,
    "${aws_s3_bucket.static.arn}/*"]
  }

  statement {
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.this.arn]
  }

  statement {
    actions = [
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule"
    ]
    resources = [
      aws_lb_listener.prd.arn,
      aws_lb_listener.qa.arn,
      "${replace(aws_lb_listener.prd.arn, "listener", "listener-rule")}/*",
      "${replace(aws_lb_listener.qa.arn, "listener", "listener-rule")}/*"
    ]
  }

  statement {
    actions = [
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = [aws_iam_role.ecs_execution.arn]
  }

  statement {
    actions = [
      "ecs:DescribeServices",
      "ecs:CreateTaskSet",
      "ecs:UpdateServicePrimaryTaskSet",
      "ecs:DeleteTaskSet",
    ]
    resources = [
      format("arn:aws:ecs:%s:%s:task-set/%s/%s/*", data.aws_region.current.name, data.aws_caller_identity.current.account_id, aws_ecs_cluster.this.name, aws_ecs_service.this.name),
      aws_ecs_service.this.id
    ]
  }
}
#"
resource "aws_iam_policy" "codedeploy" {
  name   = format("%s-%s", var.application_name, "codedeploy")
  policy = data.aws_iam_policy_document.codedeploy.json
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = aws_iam_policy.codedeploy.arn
}
