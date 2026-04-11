locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "random_password" "db" {
  length  = 32
  special = true
  # Limit special characters to those safe for JDBC URLs
  override_special = "!#$%^&*()-_=+[]{}|;:,.<>?"
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet"
  subnet_ids = var.subnet_ids

  tags = { Name = "${local.name_prefix}-db-subnet" }
}

resource "aws_db_instance" "main" {
  identifier     = "${local.name_prefix}-db"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]

  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = { Name = "${local.name_prefix}-db" }
}

# Store database password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project}/${var.environment}/db-password"

  tags = { Name = "${local.name_prefix}-db-password" }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}

# Placeholder for Anthropic API key (real value set out-of-band)
resource "aws_secretsmanager_secret" "anthropic_api_key" {
  name = "${var.project}/${var.environment}/anthropic-api-key"

  tags = { Name = "${local.name_prefix}-anthropic-api-key" }
}

resource "aws_secretsmanager_secret_version" "anthropic_api_key" {
  secret_id     = aws_secretsmanager_secret.anthropic_api_key.id
  secret_string = "CHANGE_ME"
}
