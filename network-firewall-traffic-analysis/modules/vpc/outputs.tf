################################################################################
# VPC
################################################################################

output "arn" {
  description = "Amazon Resource Name (ARN) of VPC."
  value       = aws_vpc.this.arn
}

output "id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "main_route_table_id" {
  description = "The ID of the main route table associated with this VPC. Note that you can change a VPC's main route table by using an aws_main_route_table_association.."
  value       = aws_vpc.this.main_route_table_id
}

################################################################################
# PUBLIC
################################################################################

output "public_subnet_id_list" {
  description = "The ID of the public subnet."
  value       = [for key, subnet in aws_subnet.public : subnet.id]
}

output "public_subnet_arn_list" {
  description = "The ARN of the public subnet."
  value       = [for key, subnet in aws_subnet.public : subnet.arn]
}

output "public_subnet_id_map" {
  description = "The ID of the public subnet."
  value       = { for key, subnet in aws_subnet.public : key => subnet.id }
}

output "public_subnet_arn_map" {
  description = "The ARN of the public subnet."
  value       = { for key, subnet in aws_subnet.public : key => subnet.arn }
}

output "public_route_table_id" {
  description = "The ID of the public routing table."
  value       = local.create_public_subnets ? aws_route_table.public[0].id : null
}

output "public_route_table_arn" {
  description = "The ID of the public routing table."
  value       = local.create_public_subnets ? aws_route_table.public[0].arn : null
}

output "igw_id" {
  description = "The ID of the Internet Gateway."
  value       = local.create_public_subnets ? aws_internet_gateway.this[0].id : null
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway."
  value       = local.create_public_subnets ? aws_internet_gateway.this[0].arn : null
}


################################################################################
# PRIVATE
################################################################################

output "private_subnet_map" {
  description = "The complete map of the private subnet."
  value       = aws_subnet.private
}

output "private_subnet_id_list" {
  description = "The ID of the private subnet."
  value       = [for key, subnet in aws_subnet.private : subnet.id]
}

output "private_subnet_arn_list" {
  description = "The ARN of the private subnet."
  value       = [for key, subnet in aws_subnet.private : subnet.arn]
}

output "private_subnet_id_map" {
  description = "The ID of the private subnet."
  value       = { for key, subnet in aws_subnet.private : key => subnet.id }
}

output "private_subnet_arn_map" {
  description = "The ARN of the private subnet."
  value       = { for key, subnet in aws_subnet.private : key => subnet.arn }
}

output "private_route_table_id_list" {
  description = "The ID of the private routing table."
  value       = [for key, table in aws_route_table.private : table.id]
}

output "private_route_table_arn_list" {
  description = "The ARN of the private route table."
  value       = [for key, table in aws_route_table.private : table.arn]
}

output "private_route_table_id_map" {
  description = "The ID of the private routing table."
  value       = { for key, table in aws_route_table.private : key => table.id }
}

output "private_route_table_arn_map" {
  description = "The ARN of the private route table."
  value       = { for key, table in aws_route_table.private : key => table.arn }
}

################################################################################
# TGW
################################################################################

output "tgw_subnet_id_list" {
  description = "The ID of the tgw subnet."
  value       = [for key, subnet in aws_subnet.tgw : subnet.id]
}

output "tgw_subnet_arn_list" {
  description = "The ARN of the tgw subnet."
  value       = [for key, subnet in aws_subnet.tgw : subnet.arn]
}

output "tgw_subnet_id_map" {
  description = "The ID of the tgw subnet."
  value       = { for key, subnet in aws_subnet.tgw : key => subnet.id }
}

output "tgw_subnet_arn_map" {
  description = "The ARN of the tgw subnet."
  value       = { for key, subnet in aws_subnet.tgw : key => subnet.arn }
}

output "tgw_route_table_id_list" {
  description = "The ID of the tgw routing table."
  value       = [for key, table in aws_route_table.tgw : table.id]
}

output "tgw_route_table_arn_list" {
  description = "The ARN of the tgw route table."
  value       = [for key, table in aws_route_table.tgw : table.arn]
}

output "tgw_route_table_id_map" {
  description = "The ID of the tgw routing table."
  value       = { for key, table in aws_route_table.tgw : key => table.id }
}

output "tgw_route_table_arn_map" {
  description = "The ARN of the tgw route table."
  value       = { for key, table in aws_route_table.tgw : key => table.arn }
}
