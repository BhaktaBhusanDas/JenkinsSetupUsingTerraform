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

variable "dockerhub_username" {
  description = "Docker Hub username"
  type        = string
}

variable "dockerhub_password" {
  description = "Docker Hub password or access token"
  type        = string
}

variable "github_token" {
  description = "Github token to update the Webhook."
  type        = string
}

variable "github_owner" {
  description = "Your GitHub username."
  type        = string
}

variable "github_repo" {
  description = "Name of the target repository."
  type        = string
}

variable "github_webhook_id" {
  description = "ID of the target webhook."
  type        = string
}