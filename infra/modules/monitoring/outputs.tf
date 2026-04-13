output "amp_workspace_id" {
  description = "ID of the AMP workspace"
  value       = aws_prometheus_workspace.main.id
}

output "amp_remote_write_endpoint" {
  description = "AMP remote write endpoint URL"
  value       = "${aws_prometheus_workspace.main.prometheus_endpoint}api/v1/remote_write"
}

output "amg_workspace_id" {
  description = "ID of the AMG workspace"
  value       = aws_grafana_workspace.main.id
}

output "amg_workspace_url" {
  description = "URL of the AMG workspace"
  value       = "https://${aws_grafana_workspace.main.endpoint}"
}

output "amg_service_account_token" {
  description = "API token for the AMG service account (for dashboard provisioning)"
  value       = aws_grafana_workspace_service_account_token.dashboard.key
  sensitive   = true
}
