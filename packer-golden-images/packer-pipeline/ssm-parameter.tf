################################################################################
# SSM Paramter to store Account IDs AMI should be shared with
################################################################################

resource "aws_ssm_parameter" "secret" {
  name        = "/share-ami/account_ids"

  type        = "SecureString"
  value       = jsonencode(var.account_ids)
}