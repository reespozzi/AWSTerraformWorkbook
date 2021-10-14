output "public_ip" {
      value       = aws_instance.FirstServer.public_ip
      description = "The public IP address of the simple web server"
}
