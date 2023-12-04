output "ingress_alb_dns_name" {
  description = "DNS name of the central ingress ALB."
  value       = aws_lb.ingress.dns_name
}

output "workload_nlb_dns_name" {
  description = "DNS name of the workload NLB."
  value       = aws_lb.workload.dns_name
}

output "workload_nlb_private_ipv4" {
  description = "Private IPs of the workload NLB."
  value       = local.nlb_private_ipv4_addresses_list
}
