################################################################################
# Service Discovery namespace
################################################################################

resource "aws_service_discovery_private_dns_namespace" "this" {
  name = var.application_name
  vpc  = aws_vpc.this.id
}

################################################################################
# Service Discovery service
################################################################################

resource "aws_service_discovery_service" "this" {
  name = var.jenkins_master_identifier

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.this.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 60
      type = "A"
    }
    dns_records {
      ttl  = 60
      type = "SRV"
    }
  }
}
