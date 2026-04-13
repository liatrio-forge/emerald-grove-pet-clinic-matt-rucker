output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.networking.alb_dns_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "ci_role_arn" {
  description = "ARN of the CI role for GitHub Actions OIDC"
  value       = module.identity.ci_role_arn
}

output "tofu_role_arn" {
  description = "ARN of the Tofu role for infrastructure management"
  value       = module.identity.tofu_role_arn
}

output "amp_workspace_id" {
  description = "ID of the Amazon Managed Prometheus workspace"
  value       = module.monitoring.amp_workspace_id
}

output "amg_workspace_url" {
  description = "URL of the Amazon Managed Grafana workspace"
  value       = module.monitoring.amg_workspace_url
}
