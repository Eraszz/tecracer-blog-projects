output "clone_url_http" {
  description = "The URL to use for cloning the repository over HTTPS."
  value       = aws_codecommit_repository.this.clone_url_http
}

output "clone_url_ssh" {
  description = "The URL to use for cloning the repository over SSH."
  value       = aws_codecommit_repository.this.clone_url_ssh
}