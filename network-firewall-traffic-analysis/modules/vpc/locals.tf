################################################################################
# Locals
################################################################################

locals {

  ################################################################################
  # PUBLIC
  ################################################################################

  create_public_custom_routes = length(var.public_custom_routes) > 0 ? true : false
  create_public_subnets       = length(var.public_subnets) > 0 ? true : false


  ################################################################################
  # PRIVATE
  ################################################################################

  private_custom_routes_list = flatten([
    for index, route in var.private_custom_routes : [
      for key, subnet in aws_subnet.private : merge(route, {
        route_index = index
        subnet_id   = subnet.id
        subnet_key  = key
      })
    ]
  ])

  private_custom_routes_map = {
    for value in local.private_custom_routes_list : "${value.subnet_key}_${value.route_index}" => value
  }


  ################################################################################
  # TGW
  ################################################################################

  tgw_custom_routes_list = flatten([
    for index, route in var.tgw_custom_routes : [
      for key, subnet in aws_subnet.tgw : merge(route, {
        route_index = index
        subnet_id   = subnet.id
        subnet_key  = key
      })
    ]
  ])

  tgw_custom_routes_map = {
    for value in local.tgw_custom_routes_list : "${value.subnet_key}_${value.route_index}" => value
  }

  tgw_custom_routes_specific_list = flatten([
    for index, route in var.tgw_custom_routes_specific : [
      for key, subnet in aws_subnet.tgw : merge(route, {
        route_index = index
        subnet_id   = subnet.id
        subnet_key  = key
      }) if subnet.availability_zone == route.availability_zone
    ]
  ])

  tgw_custom_routes_specific_map = {
    for value in local.tgw_custom_routes_specific_list : "${value.subnet_key}_${value.route_index}" => value
  }
}
