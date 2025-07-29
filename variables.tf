variable "jenkins_admin_username" {
  type        = string
  default     = "Admin"
  description = "Jenkins admin username"
}
 
variable "jenkins_admin_password" {
  type        = string
  default     = "admin123"
  description = "Jenkins admin password"
  sensitive = true
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name"
}

variable "jenkins_plugins" {
  type        = list(string)
  default     = [
    "build-timeout",
    "credentials-binding",
    "timestamper",
    "ws-cleanup",
    "ant",
    "gradle",
    "workflow-aggregator",
    "pipeline-github-lib",
    "pipeline-stage-view",
    "git",
    "ssh-slaves",
    "matrix-auth",
    "pam-auth",
    "ldap",
    "email-ext",
    "mailer"
  ]
  description = "List of Jenkins plugins to install"
}
