output "vpn_output_map" {
  description = "Output map containing all the necessary VPN information"
  value       = local.vpn_output_map
  sensitive   = true
}