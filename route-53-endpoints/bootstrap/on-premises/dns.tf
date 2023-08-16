################################################################################
# DNS EC2
################################################################################

resource "aws_instance" "dns" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.amazon_2.id
  subnet_id              = local.private_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.this.name
  vpc_security_group_ids = [aws_security_group.dns.id]

  private_ip = local.dns_server_ip

  user_data = templatefile("${path.module}/src/dns_user_data.sh", {
    on_premises_cidr    = var.vpc_cidr_block
    dns_server_ip       = local.dns_server_ip
    server_ip           = local.server_ip
    amazon_provided_dns = cidrhost(var.vpc_cidr_block, 2)
    local_domain_name   = "${var.application_name}.com"

    aws_site_cidr        = var.aws_network.cidr_range
    aws_site_domain_name = var.aws_network.domain_name
  })

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = { "Name" = "${var.application_name}-DNS" }
}


################################################################################
# DNS Security Group
################################################################################

resource "aws_security_group" "dns" {
  name   = "${var.application_name}-dns"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "dns_udp_egress" {
  security_group_id = aws_security_group.dns.id

  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  cidr_blocks = [var.vpc_cidr_block, var.aws_network.cidr_range]
}

resource "aws_security_group_rule" "dns_tcp_egress" {
  security_group_id = aws_security_group.dns.id

  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr_block, var.aws_network.cidr_range]
}


resource "aws_security_group_rule" "dns_https_egress" {
  security_group_id = aws_security_group.dns.id

  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "dns_udp_ingress" {
  security_group_id = aws_security_group.dns.id

  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  cidr_blocks = [var.vpc_cidr_block, var.aws_network.cidr_range]
}

resource "aws_security_group_rule" "dns_tcp_ingress" {
  security_group_id = aws_security_group.dns.id

  type        = "ingress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr_block, var.aws_network.cidr_range]
}

resource "aws_security_group_rule" "dns_icmp_lan_ingress" {
  security_group_id = aws_security_group.dns.id

  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "icmp"
  source_security_group_id = aws_security_group.lan_eni.id
}

resource "aws_security_group_rule" "dns_icmp_server_ingress" {
  security_group_id = aws_security_group.dns.id

  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "icmp"
  source_security_group_id = aws_security_group.server.id
}
