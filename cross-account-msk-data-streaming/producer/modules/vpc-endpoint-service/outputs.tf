################################################################################
# LB outputs
################################################################################

output "lb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "lb_id" {
  description = "The ARN of the load balancer"
  value       = aws_lb.this.id
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "lb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record)."
  value       = aws_lb.this.zone_id
}


################################################################################
# LB target group outputs
################################################################################

output "target_group_arn" {
  description = "ARN of the Target Group (matches id)."
  value       = aws_lb_target_group.this.arn
}

output "target_group_id" {
  description = "ARN of the Target Group (matches arn)."
  value       = aws_lb_target_group.this.id
}

output "target_group_name" {
  description = "Name of the Target Group."
  value       = aws_lb_target_group.this.name
}


################################################################################
# VPC Endpoint Service ouputs
################################################################################

output "service_id" {
  description = "The ID of the VPC endpoint service."
  value       = aws_vpc_endpoint_service.this.id
}

output "service_availability_zones" {
  description = "The Availability Zones in which the service is available."
  value       = aws_vpc_endpoint_service.this.availability_zones
}

output "service_arn" {
  description = "The Amazon Resource Name (ARN) of the VPC endpoint service."
  value       = aws_vpc_endpoint_service.this.arn
}

output "service_base_endpoint_dns_names" {
  description = "The DNS names for the service."
  value       = aws_vpc_endpoint_service.this.base_endpoint_dns_names
}

output "service_manages_vpc_endpoints" {
  description = "Whether or not the service manages its VPC endpoints - true or false."
  value       = aws_vpc_endpoint_service.this.manages_vpc_endpoints
}

output "service_name" {
  description = "The service name."
  value       = aws_vpc_endpoint_service.this.service_name
}

output "service_type" {
  description = "The service type, Gateway or Interface."
  value       = aws_vpc_endpoint_service.this.service_type
}
