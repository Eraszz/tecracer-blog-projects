module "workload" {
  source = "../modules/vpc"

  name               = "workload"
  cidr_block         = var.workload_vpc_cidr_range
  availability_zones = var.workload_vpc_availability_zones
  private_subnets    = var.workload_vpc_private_subnets
  tgw_subnets        = var.workload_vpc_tgw_subnets

  tgw_custom_routes = [{
    destination_cidr_block = "0.0.0.0/0"
    transit_gateway_id     = aws_ec2_transit_gateway.this.id
  }]

  private_custom_routes = [{
    destination_cidr_block = "0.0.0.0/0"
    transit_gateway_id     = aws_ec2_transit_gateway.this.id
  }]
}

################################################################################
# workload EC2
################################################################################

resource "aws_instance" "workload" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.amazon_2.id
  subnet_id              = module.workload.private_subnet_id_list[0]
  vpc_security_group_ids = [aws_security_group.workload.id]
  iam_instance_profile   = aws_iam_instance_profile.client.name

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = file("${path.module}/src/web_server.sh")

  tags = { "Name" = format("%s-%s", var.application_name, "workload") }

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.this,
    module.egress,
    aws_networkfirewall_firewall.this
  ]

}


################################################################################
# Workload Security Group
################################################################################

resource "aws_security_group" "workload" {
  name   = format("%s-%s", var.application_name, "workload")
  vpc_id = module.workload.id
}

resource "aws_security_group_rule" "workload_egress" {
  security_group_id = aws_security_group.workload.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "workload_ingress" {
  security_group_id = aws_security_group.workload.id

  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nlb_workload.id
}


################################################################################
# NLB
################################################################################

resource "aws_lb" "workload" {
  name                             = format("%s-%s", substr(var.application_name, 0, 16), "workload")
  load_balancer_type               = "network"
  internal                         = true
  security_groups                  = [aws_security_group.nlb_workload.id]
  ip_address_type                  = "ipv4"
  enable_cross_zone_load_balancing = true

  dynamic "subnet_mapping" {
    for_each = module.workload.private_subnet_id_list

    content {
      subnet_id            = subnet_mapping.value
      private_ipv4_address = cidrhost(var.workload_vpc_private_subnets[index(module.workload.private_subnet_id_list, subnet_mapping.value)], 10)
    }
  }
}

################################################################################
# NLB HTTP TCP listener
################################################################################

resource "aws_lb_listener" "workload" {
  load_balancer_arn = aws_lb.workload.arn
  protocol          = "TCP"

  port = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.workload.arn
  }
}

################################################################################
# NLB target groups
################################################################################

resource "aws_lb_target_group" "workload" {
  name        = format("%s-%s", substr(var.application_name, 0, 16), "workload")
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = module.workload.id

  health_check {
    enabled  = true
    protocol = "TCP"
  }
}

################################################################################
# NLB Target Group Attachment
################################################################################

resource "aws_lb_target_group_attachment" "workload" {
  target_group_arn = aws_lb_target_group.workload.arn
  target_id        = aws_instance.workload.private_ip
  port             = 80
}

################################################################################
# NLB security group
################################################################################

resource "aws_security_group" "nlb_workload" {
  name   = format("%s-%s", var.application_name, "nlb_workload")
  vpc_id = module.workload.id
}

resource "aws_security_group_rule" "nlb_workload_ingress" {
  security_group_id = aws_security_group.nlb_workload.id

  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8", "172.31.0.0/16"]
}

resource "aws_security_group_rule" "nlb_workload_egress" {
  security_group_id = aws_security_group.nlb_workload.id

  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.workload.id
}