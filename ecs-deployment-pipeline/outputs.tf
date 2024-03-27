output "webserver_url" {
  description = "URL of the web server"
  value       = "http://${aws_lb.this.dns_name}"
}

output "webserver_url_qa" {
  description = "URL of the web server"
  value       = "http://${aws_lb.this.dns_name}:8080"
}

output "codecommit_clone_url_http" {
  description = "The URL to use for cloning the repository over HTTPS."
  value = aws_codecommit_repository.this.clone_url_http
}

output "codecommit_clone_url_ssh" {
  description = "The URL to use for cloning the repository over SSH."
  value = aws_codecommit_repository.this.clone_url_ssh
}