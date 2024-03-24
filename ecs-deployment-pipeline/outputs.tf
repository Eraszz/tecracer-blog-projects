output "webserver_url" {
  description = "URL of the web server"
  value       = "http://${aws_lb.this.dns_name}"
}