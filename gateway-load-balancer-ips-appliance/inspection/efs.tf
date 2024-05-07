################################################################################
# EFS
################################################################################

resource "aws_efs_file_system" "this" {
  creation_token   = var.application_name
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
}


################################################################################
# EFS mount targets
################################################################################

resource "aws_efs_mount_target" "this" {
  for_each = aws_subnet.private

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value.id
  security_groups = [aws_security_group.efs.id]
}


################################################################################
# EFS security group
################################################################################

resource "aws_security_group" "efs" {
  name   = format("%s-%s", var.application_name, "efs")
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "efs_ingress" {
  security_group_id = aws_security_group.efs.id

  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.suricata.id
}

################################################################################
# EFS access policy
################################################################################

data "aws_iam_policy_document" "efs" {
  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]

    effect = "Allow"

    resources = [
      aws_efs_file_system.this.arn,
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.suricata.arn]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }

    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }
}

resource "aws_efs_file_system_policy" "this" {
  file_system_id = aws_efs_file_system.this.id
  policy         = data.aws_iam_policy_document.efs.json
}
