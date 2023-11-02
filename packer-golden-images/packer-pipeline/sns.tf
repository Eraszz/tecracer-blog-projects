################################################################################
# SNS Topic
################################################################################

resource "aws_sns_topic" "this" {
  name         = var.application_name
  display_name = var.application_name
}


################################################################################
# SNS Topic Policy
################################################################################

resource "aws_sns_topic_policy" "this" {
  arn = aws_sns_topic.this.arn

  policy = data.aws_iam_policy_document.sns.json
}

data "aws_iam_policy_document" "sns" {
  statement {
    actions = [
      "SNS:Publish"
    ]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com", "events.amazonaws.com"]
    }
    resources = [
      aws_sns_topic.this.arn
    ]
    /*condition {
      test     = "ArnEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.id]
    }*/
  }
}


################################################################################
# SNS Subscription
################################################################################

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.sns_endpoint
}
