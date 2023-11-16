locals {
  ssm_parameter_value = [for v in var.account_ids : { "UserId" : v }]
}

################################################################################
# SSM Paramter to store Account IDs AMI should be shared with
################################################################################

resource "aws_ssm_parameter" "secret" {
  name = "/share-ami/account_ids"

  type  = "SecureString"
  value = jsonencode(local.ssm_parameter_value)
}