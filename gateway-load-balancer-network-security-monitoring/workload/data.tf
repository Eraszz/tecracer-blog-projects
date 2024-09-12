################################################################################
# GLWB Secret
################################################################################

data "aws_secretsmanager_secret" "this" {
  arn = var.secretsmanager_secret_arn
}

data "aws_secretsmanager_secret_version" "this" {
  secret_id = data.aws_secretsmanager_secret.this.id
}

################################################################################
# Get ALB ENIs
################################################################################

data "aws_network_interface" "alb" {
  for_each = aws_subnet.public

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.this.arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [each.value.id]
  }
}