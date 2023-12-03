resource "aws_glue_registry" "this" {
  registry_name = var.application_name
}