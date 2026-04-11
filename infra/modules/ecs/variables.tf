variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "container_image" {
  description = "Container image URL (ECR repository URL with tag)"
  type        = string
}

variable "container_port" {
  description = "Port the application listens on"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Fargate task CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "memory" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 2048
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS tasks"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "db_endpoint" {
  description = "RDS database endpoint (host:port)"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret for database password"
  type        = string
}

variable "anthropic_api_key_secret_arn" {
  description = "ARN of the Secrets Manager secret for Anthropic API key"
  type        = string
}
