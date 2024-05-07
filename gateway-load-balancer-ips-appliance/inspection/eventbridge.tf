################################################################################
# EventBrdige Rule
################################################################################

resource "aws_cloudwatch_event_rule" "new_custom_rule" {
  name        = format("%s-%s", var.application_name, "custom-suricata-rules")
  description = "Upload and reload Suricata Rules"
  role_arn    = aws_iam_role.eventbridge.arn

  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : {
        "name" : [aws_s3_bucket.this.id]
      },
      "object" : {
        "key" : [var.custom_rule_file_name]
      }
    }
  })
}

resource "aws_cloudwatch_event_rule" "daily_suricata_update" {
  name        = format("%s-%s", var.application_name, "daily-suricata-update")
  description = "Update Suricata Rules"
  role_arn    = aws_iam_role.eventbridge.arn

  schedule_expression = "cron(0 0 * * ? *)"
}

################################################################################
# EventBrdige Rule
################################################################################

resource "aws_cloudwatch_event_target" "new_custom_rule" {
  target_id = var.application_name
  arn       = "arn:aws:ssm:${data.aws_region.current.name}::document/AWS-RunShellScript"
  role_arn  = aws_iam_role.eventbridge.arn

  input = jsonencode({
    commands = [
      "sudo aws s3 --region ${data.aws_region.current.name} sync s3://${aws_s3_bucket.this.id} /var/lib/suricata/rules/ --include='${var.custom_rule_file_name}' --exact-timestamp",
      "sudo suricata-update",
      "sudo kill -usr2 $(pidof suricata)"
    ]
  })

  rule = aws_cloudwatch_event_rule.new_custom_rule.name

  run_command_targets {
    key    = "tag:tier"
    values = ["ips"]
  }
}

resource "aws_cloudwatch_event_target" "daily_suricata_update" {
  target_id = var.application_name
  arn       = "arn:aws:ssm:${data.aws_region.current.name}::document/AWS-RunShellScript"
  role_arn  = aws_iam_role.eventbridge.arn

  input = jsonencode({
    commands = [
      "sudo suricata-update",
      "sudo kill -usr2 $(pidof suricata)"
    ]
  })

  rule = aws_cloudwatch_event_rule.daily_suricata_update.name

  run_command_targets {
    key    = "tag:tier"
    values = ["ips"]
  }
}

################################################################################
# IAM role for EventBrdige
################################################################################

resource "aws_iam_role" "eventbridge" {
  name = format("%s-%s", var.application_name, "eventbridge")

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

data "aws_iam_policy_document" "eventbridge" {

  statement {
    effect = "Allow"
    actions = [
      "ssm:SendCommand"
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/tier"
      values   = ["ips"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:SendCommand"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}::document/AWS-RunShellScript",
    ]
  }
}

resource "aws_iam_policy" "eventbridge" {
  name   = format("%s-%s", var.application_name, "eventbridge")
  policy = data.aws_iam_policy_document.eventbridge.json
}

resource "aws_iam_role_policy_attachment" "eventbridge" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.eventbridge.arn
}