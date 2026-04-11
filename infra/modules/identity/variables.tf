variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in org/repo format (e.g., liatrio-forge/emerald-grove-pet-clinic-matt-rucker)"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository (for CI push permissions)"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster (for deploy permissions)"
  type        = string
  default     = "*"
}

variable "ecs_service_arn" {
  description = "ARN of the ECS service (for deploy permissions)"
  type        = string
  default     = "*"
}
