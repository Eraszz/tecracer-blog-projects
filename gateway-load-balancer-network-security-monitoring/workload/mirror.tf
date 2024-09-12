################################################################################
# Traffic Mirror Session
################################################################################

resource "aws_ec2_traffic_mirror_filter" "this" {
  description      = "traffic mirror filter amazon DNS"
  network_services = ["amazon-dns"]
}

resource "aws_ec2_traffic_mirror_target" "this" {
  gateway_load_balancer_endpoint_id = aws_vpc_endpoint.this[keys(aws_subnet.private)[0]].id
}

resource "aws_ec2_traffic_mirror_filter_rule" "this" {
  description              = "all ingress"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.this.id
  destination_cidr_block   = "0.0.0.0/0"
  source_cidr_block        = "0.0.0.0/0"
  rule_number              = 1
  rule_action              = "accept"
  traffic_direction        = "ingress"
}

resource "aws_ec2_traffic_mirror_session" "this" {
    for_each = data.aws_network_interface.alb

  network_interface_id     = each.value.id
  session_number           = 1
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.this.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.this.id
}