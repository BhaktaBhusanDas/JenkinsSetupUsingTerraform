output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_instance.Jenkins.public_ip}:8080"
}

output "Application_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_instance.Jenkins.public_ip}:3000"
}

output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = aws_instance.Jenkins.public_ip
}

output "jenkins_private_ip" {
  description = "Private IP of Jenkins server"
  value       = aws_instance.Jenkins.private_ip
}

output "admin_credentials" {
  description = "Jenkins admin credentials"
  value = {
    username = var.jenkins_admin_username
    password = var.jenkins_admin_password
  }
  sensitive = true
}
