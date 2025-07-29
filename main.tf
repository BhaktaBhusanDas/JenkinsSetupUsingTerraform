resource "aws_instance" "Jenkins" {
  ami                    = "ami-0150ccaf51ab55a51"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ssh_http.id]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "JenkinsServer"
    Owner       = "Bhakta Bhusan Das"
    Environment = var.environment
  }

  user_data_base64 = base64encode(templatefile("${path.module}/jenkins_bootstrap.sh", {
    admin_username = var.jenkins_admin_username
    admin_password = var.jenkins_admin_password
  }))

  user_data_replace_on_change = true

}

output "public_ip" {
  value       = aws_instance.Jenkins.public_ip
  description = "Prints the public IP of of the Jenkins server."
}