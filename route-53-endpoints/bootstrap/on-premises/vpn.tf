################################################################################
# PF Sense Firewall EC2
################################################################################

resource "aws_instance" "firewall" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.amazon_2.id
  subnet_id              = local.public_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.this.name
  vpc_security_group_ids = [aws_security_group.wan_eni.id]

  private_ip = local.vpn_wan_ip

  source_dest_check = false

  user_data = templatefile("${path.module}/src/strongswan_user_data.sh", {
    on_premises_network_cidr_range = var.vpc_cidr_block
    aws_network_cidr_range = var.aws_network.cidr_range
    on_premises_private_ip = local.vpn_wan_ip
    on_premises_peer_ip = aws_eip.this.public_ip 
    aws_network_peer_ip_1 = var.aws_network.peer_ips[0]
    aws_network_peer_ip_2 = var.aws_network.peer_ips[1]
    vpn_tunnel1_preshared_key = var.aws_network.preshared_keys[0]
    vpn_tunnel2_preshared_key = var.aws_network.preshared_keys[1]
  })

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = { "Name" = "${var.application_name}-Strongswan" }

}

resource "aws_eip" "this" {
  domain = "vpc"
}

resource "aws_eip_association" "this" {
  allocation_id        = aws_eip.this.id
  network_interface_id = aws_instance.firewall.primary_network_interface_id
}

################################################################################
# PF Sense Firewall LAN ENI
################################################################################

resource "aws_network_interface" "this" {
  subnet_id = local.private_subnet_ids[0]

  security_groups   = [aws_security_group.lan_eni.id]
  source_dest_check = false

  private_ips = [local.vpn_lan_ip]
}


resource "aws_network_interface_attachment" "this" {
  instance_id          = aws_instance.firewall.id
  network_interface_id = aws_network_interface.this.id
  device_index         = 1
}


################################################################################
# Firewall LAN ENI Security Group
################################################################################

resource "aws_security_group" "lan_eni" {
  name   = "${var.application_name}-lan-eni"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "lan_eni_ingress" {
  security_group_id = aws_security_group.lan_eni.id

  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = local.private_subnet_cidrs
}

resource "aws_security_group_rule" "lan_eni_egress" {
  security_group_id = aws_security_group.lan_eni.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = local.private_subnet_cidrs
}

################################################################################
# Firewall WAN ENI Security Group
################################################################################

resource "aws_security_group" "wan_eni" {
  name   = "${var.application_name}-wan-eni"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "config_ingress" {
  security_group_id = aws_security_group.wan_eni.id

  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

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
