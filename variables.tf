variable "jenkins_admin_username" {
  type        = string
  default     = "Admin"
  description = "Jenkins admin username"
}

variable "jenkins_admin_password" {
  type        = string
  default     = "admin123"
  description = "Jenkins admin password"
  sensitive   = true
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name"
}

variable "key_name" {
  type        = string
  description = "Name of the SSH key pair to use"
}