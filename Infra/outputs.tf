output "jenkins_public_ip" {
  value       = aws_instance.jenkins_instance.public_ip
  description = "Jenkins public IP address"
}

output "jenkins_public_url" {
  value       = "http://${aws_instance.jenkins_instance.public_ip}:8080"
  description = "Jenkins web UI URL"
}

output "jenkins_private_ip" {
  value       = aws_instance.jenkins_instance.private_ip
  description = "Jenkins private IP address"
}

output "app_private_ip" {
  value       = aws_instance.app_instance.private_ip
  description = "App instance private IP address"
}

output "ssh_command_jenkins" {
  value       = "ssh -i jenkins-shared-key.pem ubuntu@${aws_instance.jenkins_instance.public_ip}"
  description = "SSH command for Jenkins instance"
}

output "scp_command_app" {
  value       = "scp -i jenkins-shared-key.pem ./jenkins-shared-key.pem ubuntu@${aws_instance.jenkins_instance.public_ip}:/home/ubuntu/jenkins-shared-key.pem "
  description = "SSH command for App instance (via Jenkins bastion)"
}

output "jenkins_credentials" {
  value = {
    username = "admin"
    password = "Admin123!"
    agent    = "app-agent"
  }
  description = "Jenkins login credentials"
  sensitive   = true
}

output "ecr_url" {
  value = aws_ecr_repository.app_repository.repository_url
}