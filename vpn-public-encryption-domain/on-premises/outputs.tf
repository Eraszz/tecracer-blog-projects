output "server_private_ip" {
    description = "Private IP of the Server"
    value = aws_instance.server.private_ip
}
