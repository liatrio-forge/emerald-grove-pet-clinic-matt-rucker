variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "emerald-grove"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 8080
}

variable "grafana_admin_email" {
  description = "Email address for the Grafana admin user in IAM Identity Center"
  type        = string
}
