module "inspection" {
  source = "../modules/vpc"

  name               = "inspection"
  cidr_block         = var.inspection_vpc_cidr_range
  availability_zones = var.inspection_vpc_availability_zones
  private_subnets    = var.inspection_vpc_firewall_subnets
  tgw_subnets        = var.inspection_vpc_tgw_subnets

  tgw_custom_routes_specific = local.firewall_endpoints

  /*
  tgw_custom_routes = [{
    destination_cidr_block = "0.0.0.0/0"
    transit_gateway_id     = aws_ec2_transit_gateway.this.id
  }]*/

  private_custom_routes = [{
    destination_cidr_block = "0.0.0.0/0"
    transit_gateway_id     = aws_ec2_transit_gateway.this.id
  }]
}


################################################################################
# Network Firewall
################################################################################

resource "aws_networkfirewall_firewall" "this" {
  name                = var.application_name
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this.arn
  vpc_id              = module.inspection.id

  dynamic "subnet_mapping" {
    for_each = module.inspection.private_subnet_id_list

    content {
      subnet_id = subnet_mapping.value
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "this" {
  name = var.application_name

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.this.arn
    }
  }
}


################################################################################
# Network Firewall Rule Group
################################################################################

resource "aws_networkfirewall_rule_group" "this" {
  capacity = 100
  name     = var.application_name
  type     = "STATEFUL"

  rule_group {
    rule_variables {
      ip_sets {
        key = "NLB_WORKLOAD"
        ip_set {
          definition = [for value in local.nlb_private_ipv4_addresses_list : "${value}/32"]
        }
      }

      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.aws_cidr_range]
        }
      }

      ip_sets {
        key = "ON_PREM_NET"
        ip_set {
          definition = [var.on_premises_cidr_range]
        }
      }

      port_sets {
        key = "HTTP"
        port_set {
          definition = [80]
        }
      }
    }

    rules_source {
      stateful_rule {

        action = var.network_firewall_on_premises_action
        header {
          destination      = "$HOME_NET"
          destination_port = "ANY"
          direction        = "FORWARD"
          protocol         = "IP"
          source           = "$ON_PREM_NET"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["2"]
        }
      }
      stateful_rule {

        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          direction        = "FORWARD"
          protocol         = "IP"
          source           = "$HOME_NET"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }
    }
  }
}

################################################################################
# Network Firewall logging
################################################################################

resource "aws_networkfirewall_logging_configuration" "this" {
  firewall_arn = aws_networkfirewall_firewall.this.arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.this.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/aws/network-firewall/${var.application_name}"

  retention_in_days = 30
}