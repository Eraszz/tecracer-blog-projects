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
  name   = "efs"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "ecs_ingress" {
  security_group_id = aws_security_group.efs.id

  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_service.id
}

################################################################################
# EFS access points
################################################################################

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/home"

    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
  }
}

################################################################################
# EFS access policy
################################################################################

data "aws_iam_policy_document" "this" {
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
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }
}

resource "aws_efs_file_system_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  policy = data.aws_iam_policy_document.this.json
}
