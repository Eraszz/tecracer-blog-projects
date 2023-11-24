################################################################################
# Firewall LAN ENI Security Group
################################################################################

resource "aws_security_group" "lan_eni" {
  name   = "${var.name}-lan-eni"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "lan_eni_ingress" {
  security_group_id = aws_security_group.lan_eni.id

  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = [data.aws_vpc.this.cidr_block]
}

resource "aws_security_group_rule" "lan_eni_egress" {
  security_group_id = aws_security_group.lan_eni.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = [data.aws_vpc.this.cidr_block]
}

################################################################################
# Firewall WAN ENI Security Group
################################################################################

resource "aws_security_group" "wan_eni" {
  name   = "${var.name}-wan-eni"
  vpc_id = var.vpc_id
}

/*
resource "aws_security_group_rule" "config_ingress" {
  security_group_id = aws_security_group.wan_eni.id

  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}*/

resource "aws_security_group_rule" "bgp_ingress" {
  security_group_id = aws_security_group.wan_eni.id

  type        = "ingress"
  from_port   = 179
  to_port     = 179
  protocol    = "tcp"
  cidr_blocks = local.aws_peer_ips_cidr
}

resource "aws_security_group_rule" "udp_500_ingress" {
  security_group_id = aws_security_group.wan_eni.id

  type        = "ingress"
  from_port   = 500
  to_port     = 500
  protocol    = "udp"
  cidr_blocks = local.aws_peer_ips_cidr
}

resource "aws_security_group_rule" "udp_4500_ingress" {
  security_group_id = aws_security_group.wan_eni.id

  type        = "ingress"
  from_port   = 4500
  to_port     = 4500
  protocol    = "udp"
  cidr_blocks = local.aws_peer_ips_cidr
}

resource "aws_security_group_rule" "esp_50_ingress" {
  security_group_id = aws_security_group.wan_eni.id

  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "50"
  cidr_blocks = local.aws_peer_ips_cidr
}

resource "aws_security_group_rule" "vpn_peer_egress" {
  security_group_id = aws_security_group.wan_eni.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}