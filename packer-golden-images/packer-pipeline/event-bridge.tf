################################################################################
# EventBridge
################################################################################

resource "aws_cloudwatch_event_rule" "this" {
  name        = var.application_name
  description = "Trigger the AWS Inspector Assessment"

  event_pattern = jsonencode({
    source = ["aws.ec2"],
    detail-type = ["EC2 Instance State-change Notification"],
    detail = {
        state = ["running"]
    }
    })
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.this.name
  arn      = aws_inspector_assessment_template.this.arn
  role_arn = aws_iam_role.event_bridge.arn
}


################################################################################
# IAM Role for EventBridge
################################################################################

resource "aws_iam_role" "event_bridge" {
  name  = "${var.application_name}-event-bridge"

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

data "aws_iam_policy_document" "event_bridge" {
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

resource "aws_iam_policy" "event_bridge" {
  name   = "event-bridge"
  policy = data.aws_iam_policy_document.event_bridge.json
}

resource "aws_iam_role_policy_attachment" "event_bridge" {
  role       = aws_iam_role.event_bridge.name
  policy_arn = aws_iam_policy.event_bridge.arn
}