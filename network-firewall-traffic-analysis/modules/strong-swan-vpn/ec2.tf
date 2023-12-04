################################################################################
# StrongSwan VPN EC2
################################################################################

resource "aws_instance" "strongswan" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.amazon_2.id
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.wan_eni.id]

  private_ip = local.vpn_wan_ip

  source_dest_check = false

  user_data = templatefile("${path.module}/src/strongswan_user_data.sh", {
    on_premises_network_cidr_range = data.aws_vpc.this.cidr_block
    aws_network_cidr_range         = var.aws_network.cidr_range
    on_premises_private_ip         = local.vpn_wan_ip
    on_premises_peer_ip            = aws_eip.this.public_ip
    aws_network_peer_ip_1          = var.aws_network.peer_ips[0]
    aws_network_peer_ip_2          = var.aws_network.peer_ips[1]
    vpn_tunnel1_preshared_key      = var.aws_network.preshared_keys[0]
    vpn_tunnel2_preshared_key      = var.aws_network.preshared_keys[1]
  })

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = { "Name" = "${var.name}-strongswan" }

}

resource "aws_eip" "this" {
  domain = "vpc"
}

resource "aws_eip_association" "this" {
  allocation_id        = aws_eip.this.id
  network_interface_id = aws_instance.strongswan.primary_network_interface_id
}

################################################################################
# Get newest Linux 2 AMI
################################################################################

data "aws_ami" "amazon_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"]
}

################################################################################
# StrongSwan VPN LAN ENI
################################################################################

resource "aws_network_interface" "this" {
  subnet_id = var.private_subnet_id

  security_groups   = [aws_security_group.lan_eni.id]
  source_dest_check = false

  private_ips = [local.vpn_lan_ip]
}


resource "aws_network_interface_attachment" "this" {
  instance_id          = aws_instance.strongswan.id
  network_interface_id = aws_network_interface.this.id
  device_index         = 1
}

