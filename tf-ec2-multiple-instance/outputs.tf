output "backend_public_ip" {
  description = "The public IP address of the Flask Backend server"
  value       = aws_instance.flask_server.public_ip
}

output "frontend_public_ip" {
  description = "The public IP address of the Express Frontend server"
  value       = aws_instance.express_server.public_ip
}

output "api_endpoint_url" {
  description = "The direct URL to the Flask JSON data"
  value       = "http://${aws_instance.flask_server.public_ip}:5000/api/names"
}

output "frontend_ui_url" {
  description = "The direct URL to the Express Web Interface"
  value       = "http://${aws_instance.express_server.public_ip}:3000"
}
