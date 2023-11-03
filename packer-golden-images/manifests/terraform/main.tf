resource "aws_ami_launch_permission" "this" {
for_each = var.account_ids

  image_id = var.ami_id
  account_id    = each.value
}