################################################################################
# EventBridge to inform of successful Inspector scan
################################################################################

resource "aws_cloudwatch_event_rule" "scan" {
  name        = format("%s-%s", var.application_name, "scan-successful")
  description = "AWS Inspector scan successful"

  event_pattern = jsonencode({
  source = ["aws.inspector2"],
  detail-type = ["Inspector2 Scan"],
  resources = [aws_instance.this.id],
  detail = {
    scan-status = ["INITIAL_SCAN_COMPLETE"]
}
})
}

resource "aws_cloudwatch_event_target" "scan" {
  rule     = aws_cloudwatch_event_rule.scan.name
  arn      = data.aws_sns_topic.this.arn
}


################################################################################
# EventBridge to inform of Inspector scan findings
################################################################################

resource "aws_cloudwatch_event_rule" "findings" {
  name        = format("%s-%s", var.application_name, "findings")
  description = "AWS Inspector scan successful"

  event_pattern = jsonencode({
  source = ["aws.inspector2"],
  detail-type = ["Inspector2 Finding"],
  resources = [aws_instance.this.id],
})
}

resource "aws_cloudwatch_event_target" "findings" {
  rule     = aws_cloudwatch_event_rule.findings.name
  arn      = data.aws_sns_topic.this.arn
}