output "db_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Database master username"
  value       = aws_db_instance.main.username
}

output "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the database password"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "anthropic_api_key_secret_arn" {
  description = "ARN of the Secrets Manager secret for the Anthropic API key"
  value       = aws_secretsmanager_secret.anthropic_api_key.arn
}
