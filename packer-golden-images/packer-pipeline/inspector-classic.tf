resource "aws_inspector_resource_group" "this" {
  tags = {
    inspect = true
  }
}

resource "aws_inspector_assessment_target" "this" {
  name               = var.application_name
  resource_group_arn = aws_inspector_resource_group.this.arn
}

resource "aws_inspector_assessment_template" "this" {
  name       = var.application_name
  target_arn = aws_inspector_assessment_target.this.arn
  duration   = 3600

  rules_package_arns = [
    "arn:aws:inspector:eu-central-1:537503971621:rulespackage/0-wNqHa8M9",
    "arn:aws:inspector:eu-central-1:537503971621:rulespackage/0-nZrAVuv8",
    "arn:aws:inspector:eu-central-1:537503971621:rulespackage/0-ZujVHEPB"
  ]

  event_subscription {
    event     = "ASSESSMENT_RUN_COMPLETED"
    topic_arn = aws_sns_topic.this.arn
  }

  event_subscription {
    event     = "FINDING_REPORTED"
    topic_arn = aws_sns_topic.this.arn
  }
}