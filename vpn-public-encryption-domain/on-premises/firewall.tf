################################################################################
# PF Sense Firewall EC2
################################################################################

resource "aws_instance" "firewall" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.pf_sense.id
  subnet_id              = local.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.wan_eni.id]

  private_ip = "192.168.0.10"
  source_dest_check = false

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {"Name" = "pfSense"}
}

resource "aws_eip_association" "this" {
  network_interface_id = aws_instance.firewall.primary_network_interface_id
  allocation_id = data.aws_eip.this.id
}

data "aws_eip" "this" {
  public_ip = var.on_premises_peer_ip
}


################################################################################
# PF Sense Firewall LAN ENI
################################################################################

resource "aws_network_interface" "this" {
  subnet_id = local.private_subnet_ids[0]

  security_groups   = [aws_security_group.lan_eni.id]
  source_dest_check = false

  private_ips       = ["192.168.1.10"]
}


resource "aws_network_interface_attachment" "this" {
  instance_id          = aws_instance.firewall.id
  network_interface_id = aws_network_interface.this.id
  device_index         = 1
}


################################################################################
# Get newest PF Sense AMI
################################################################################

data "aws_ami" "pf_sense" {
  most_recent = true

  filter {
    name   = "name"
    values = ["pfSense-plus-ec2-23.01*"]
  }
  owners = ["679593333241"]
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

resource "aws_security_group_rule" "vpn_peer_egress" {
  security_group_id = aws_security_group.wan_eni.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "udp_500_ingress" {
  security_group_id = aws_security_group.wan_eni.id

  type        = "ingress"
  from_port   = 500
  to_port     = 500
  protocol    = "udp"
  cidr_blocks = ["${var.aws_peer_ip}/32"]
}

resource "aws_security_group_rule" "udp_4500_ingress" {
  security_group_id = aws_security_group.wan_eni.id

  type        = "ingress"
  from_port   = 4500
  to_port     = 4500
  protocol    = "udp"
  cidr_blocks = ["${var.aws_peer_ip}/32"]
}

resource "aws_security_group_rule" "esp_50_ingress" {
  security_group_id = aws_security_group.wan_eni.id

  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "50"
  cidr_blocks = ["${var.aws_peer_ip}/32"]
}