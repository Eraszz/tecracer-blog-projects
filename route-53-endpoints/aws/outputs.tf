output "route53_inbound_endpoint_ips" {
  description = "IPs of Route53 resolver inbound endpoints"
  value       = data.aws_route53_resolver_endpoint.inbound.ip_addresses
}