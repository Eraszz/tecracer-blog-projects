################################################################################
# EventBridge to install Inspector Agent on EC2
################################################################################

resource "aws_cloudwatch_event_rule" "install_agent" {
  name        = format("%s-%s", var.application_name, "install-agent")
  description = "Install Inspector Agent on EC2"

  event_pattern = jsonencode({
    source      = ["aws.ec2"],
    detail-type = ["EC2 Instance State-change Notification"],
    detail = {
      state = ["running"],
      tagSpecificationSet = {
        items = {
          tags = {
            inspect = ["true"]
          }
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "install_agent" {
  rule     = aws_cloudwatch_event_rule.install_agent.name
  arn      = "arn:aws:ssm:${data.aws_region.current.name}::document/AmazonInspector-ManageAWSAgent"
  role_arn = aws_iam_role.install_agent.arn

  run_command_targets {
    key    = "tag:inspect"
    values = ["true"]
  }
}


################################################################################
# IAM Role for EventBridge
################################################################################

resource "aws_iam_role" "install_agent" {
  name = format("%s-%s-%s", var.application_name, "event-bridge", "install-agent")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "install_agent" {
  statement {
    sid = "runCommand"
    actions = [
      "ssm:SendCommand",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/inspect"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "install_agent" {
  name   = format("%s-%s", "event-bridge", "install-agent")
  policy = data.aws_iam_policy_document.install_agent.json
}

resource "aws_iam_role_policy_attachment" "install_agent" {
  role       = aws_iam_role.install_agent.name
  policy_arn = aws_iam_policy.install_agent.arn
}


################################################################################
# EventBridge to run Inspector Assessment
################################################################################

resource "aws_cloudwatch_event_rule" "run_assessment" {
  name        = format("%s-%s", var.application_name, "run-assessment")
  description = "Trigger the AWS Inspector Assessment"

  event_pattern = jsonencode({
    source      = ["aws.ssm"],
    detail-type = ["EC2 Command Status-change Notification"],
    detail = {
      state = ["Success"],
      tagSpecificationSet = {
        items = {
          tags = {
            inspect = ["true"]
          }
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "run_assessment" {
  rule     = aws_cloudwatch_event_rule.run_assessment.name
  arn      = aws_inspector_assessment_template.this.arn
  role_arn = aws_iam_role.run_assessment.arn
}


################################################################################
# IAM Role for EventBridge
################################################################################

resource "aws_iam_role" "run_assessment" {
  name = format("%s-%s-%s", var.application_name, "event-bridge", "run-assessment")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "run_assessment" {
  statement {
    sid = "startAssessment"
    actions = [
      "inspector:StartAssessmentRun",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "run_assessment" {
  name   = format("%s-%s", "event-bridge", "run-assessment")
  policy = data.aws_iam_policy_document.run_assessment.json
}

resource "aws_iam_role_policy_attachment" "run_assessment" {
  role       = aws_iam_role.run_assessment.name
  policy_arn = aws_iam_policy.run_assessment.arn
}