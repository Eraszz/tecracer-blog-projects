################################################################################
# Cloudwatch Log Groups
################################################################################

resource "aws_cloudwatch_log_group" "suricata_log" {
  name              = "/suricata/suricata.log"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "fast_log" {
  name              = "/suricata/fast.log"
  retention_in_days = 30
}
