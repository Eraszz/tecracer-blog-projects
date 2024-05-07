################################################################################
# SSM Parameter
################################################################################

resource "aws_ssm_parameter" "this" {
  name = format("%s-%s", var.application_name, "cw-agent-config")
  type = "String"
  value = templatefile("${path.module}/config/cw-agent-config.json.tmpl", {
    suricata_log_group_name = aws_cloudwatch_log_group.suricata_log.name
    fast_log_group_name     = aws_cloudwatch_log_group.fast_log.name
  })
}