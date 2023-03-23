################################################################################
# Aurora Serverless
################################################################################

resource "aws_rds_cluster" "aurora_mysql" {
  cluster_identifier      = "aurora-mysql"
  engine                  = "aurora-mysql"
  engine_mode             = "serverless"
  database_name           = "test"
  backup_retention_period = 30

  master_password = var.master_password
  master_username = var.master_username

  scaling_configuration {
    auto_pause     = false
    max_capacity   = 2
    min_capacity   = 1
    timeout_action = "RollbackCapacityChange"
  }

  vpc_security_group_ids = [aws_security_group.aurora_mysql.id]

  storage_encrypted = true
  enable_http_endpoint = true
  skip_final_snapshot = true
}

################################################################################
# RDS Subnet Group
################################################################################

resource "aws_db_subnet_group" "aurora_mysql" {
  name       = "aurora_mysql"
  subnet_ids = data.aws_subnets.default.ids
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "aurora_mysql" {
  name   = "aurora-mysql"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "ingress" {
  security_group_id = aws_security_group.aurora_mysql.id

  type      = "ingress"
  from_port = 3306
  to_port   = 3306
  protocol  = "tcp"
  self      = true
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.aurora_mysql.id

  type      = "egress"
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
}