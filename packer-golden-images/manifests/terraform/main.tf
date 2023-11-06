data "aws_ssm_parameter" "this" {
  name = var.ssm_parameter_path
}

locals {
  account_ids = nonsensitive(jsondecode(data.aws_ssm_parameter.this.value))
}

resource "aws_ami_launch_permission" "this" {
for_each = local.account_ids

  image_id = var.ami_id
  account_id    = each.value
}