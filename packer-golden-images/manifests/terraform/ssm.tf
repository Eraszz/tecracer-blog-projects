/*
resource "aws_ssm_association" "this" {
  name = "AmazonInspector-ManageAWSAgent"

  parameters = {
    Operation = "Install"
  }

  targets {
    key    = "tag:inspect"
    values = ["true"]
  }
}
*/

