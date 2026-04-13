locals {
  name_prefix = "${var.project}-${var.environment}"
}

data "aws_region" "current" {}

# --- Amazon Managed Prometheus (AMP) ---

resource "aws_prometheus_workspace" "main" {
  alias = "${local.name_prefix}"

  tags = { Name = "${local.name_prefix}-amp" }
}

# --- Amazon Managed Grafana (AMG) ---

resource "aws_grafana_workspace" "main" {
  name                     = "${local.name_prefix}"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["PROMETHEUS"]
  role_arn                 = aws_iam_role.grafana.arn
  grafana_version          = "10.4"

  tags = { Name = "${local.name_prefix}-amg" }
}

# --- IAM Role for AMG (AMP read access) ---

data "aws_iam_policy_document" "grafana_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "grafana" {
  name               = "${local.name_prefix}-grafana"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role.json

  tags = { Name = "${local.name_prefix}-grafana" }
}

data "aws_iam_policy_document" "grafana_amp_read" {
  statement {
    actions = [
      "aps:QueryMetrics",
      "aps:GetMetricMetadata",
      "aps:GetSeries",
      "aps:GetLabels",
    ]
    resources = [aws_prometheus_workspace.main.arn]
  }
}

resource "aws_iam_role_policy" "grafana_amp_read" {
  name   = "${local.name_prefix}-grafana-amp-read"
  role   = aws_iam_role.grafana.id
  policy = data.aws_iam_policy_document.grafana_amp_read.json
}

# --- IAM Identity Center User (lookup existing) ---
# The identity store is org-managed (cross-account), so we look up
# an existing user rather than creating one.

data "aws_identitystore_user" "grafana_admin" {
  identity_store_id = var.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = var.grafana_user_email
    }
  }
}

# --- AMG Role Association (grant Identity Center user ADMIN in AMG) ---

resource "aws_grafana_role_association" "admin" {
  workspace_id = aws_grafana_workspace.main.id
  role         = "ADMIN"
  user_ids     = [data.aws_identitystore_user.grafana_admin.user_id]
}

# --- AMG Service Account + API Key (for dashboard provisioning) ---

resource "aws_grafana_workspace_service_account" "dashboard" {
  name         = "${local.name_prefix}-dashboard-sa"
  workspace_id = aws_grafana_workspace.main.id
  grafana_role = "ADMIN"
}

resource "aws_grafana_workspace_service_account_token" "dashboard" {
  name               = "${local.name_prefix}-dashboard-token"
  workspace_id       = aws_grafana_workspace.main.id
  service_account_id = aws_grafana_workspace_service_account.dashboard.service_account_id
  seconds_to_live    = 2592000 # 30 days (maximum)
}

# --- Grafana Dashboard (provisioned via API) ---
# The grafana/grafana provider can't be used here because provider configs
# cannot reference resource attributes. We use terraform_data + local-exec
# to call the Grafana HTTP API in a single apply.

resource "terraform_data" "grafana_dashboard" {
  input = {
    endpoint = aws_grafana_workspace.main.endpoint
    token    = aws_grafana_workspace_service_account_token.dashboard.key
    dashboard_json = file("${path.module}/../../dashboards/overview.json")
    amp_datasource_uid = "prometheus"
    amp_endpoint       = aws_prometheus_workspace.main.prometheus_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Create AMP data source in Grafana
      curl -sf -X POST \
        "https://${self.input.endpoint}/api/datasources" \
        -H "Authorization: Bearer ${self.input.token}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "Amazon Managed Prometheus",
          "type": "prometheus",
          "uid": "${self.input.amp_datasource_uid}",
          "url": "${self.input.amp_endpoint}",
          "access": "proxy",
          "isDefault": true,
          "jsonData": {
            "httpMethod": "POST",
            "sigV4Auth": true,
            "sigV4AuthType": "ec2_iam_role",
            "sigV4Region": "${data.aws_region.current.name}"
          }
        }' || true

      # Provision the dashboard
      curl -sf -X POST \
        "https://${self.input.endpoint}/api/dashboards/db" \
        -H "Authorization: Bearer ${self.input.token}" \
        -H "Content-Type: application/json" \
        -d "{\"dashboard\": $(cat <<'DASHBOARD'
${self.input.dashboard_json}
DASHBOARD
), \"overwrite\": true}"
    EOT
  }
}
