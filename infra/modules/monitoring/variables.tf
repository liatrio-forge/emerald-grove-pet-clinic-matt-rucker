variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "identity_store_id" {
  description = "IAM Identity Center identity store ID"
  type        = string
  default     = "d-906787324a"
}

variable "grafana_user_email" {
  description = "Email address of an existing IAM Identity Center user to grant Grafana ADMIN role"
  type        = string
}
