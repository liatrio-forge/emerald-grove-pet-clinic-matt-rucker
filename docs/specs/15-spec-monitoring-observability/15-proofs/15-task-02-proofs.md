# Task 2.0 Proof Artifacts — OpenTofu Monitoring Module

## tofu validate

```text
$ mise exec -- tofu -chdir=infra validate
Success! The configuration is valid.
```

## tofu init (with monitoring module)

```text
$ mise exec -- tofu -chdir=infra init -backend=false
Initializing modules...
- ecr in modules/ecr
- ecs in modules/ecs
- identity in modules/identity
- monitoring in modules/monitoring
- networking in modules/networking
- rds in modules/rds

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Reusing previous version of hashicorp/random from the dependency lock file
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed, key ID 0C0AF313E5FD9F80)
- Installing hashicorp/random v3.8.1...
- Installed hashicorp/random v3.8.1 (signed, key ID 0C0AF313E5FD9F80)

OpenTofu has been successfully initialized!
```

## Files Created / Modified

### New: `infra/modules/monitoring/variables.tf`

Inputs: `environment`, `project`, `identity_store_id` (default `d-906787324a`), `grafana_user_email`, `grafana_user_name`.

### New: `infra/modules/monitoring/main.tf`

Resources:

- `aws_prometheus_workspace.main` — AMP workspace
- `aws_grafana_workspace.main` — AMG workspace with AWS_SSO auth, Grafana 10.4
- `aws_iam_role.grafana` — IAM role for AMG with AMP read permissions
- `aws_identitystore_user.grafana_admin` — IAM Identity Center user
- `aws_grafana_role_association.admin` — Grants Identity Center user ADMIN in AMG
- `aws_grafana_workspace_service_account.dashboard` — Service account for dashboard provisioning
- `aws_grafana_workspace_service_account_token.dashboard` — API token for dashboard provisioning

### New: `infra/modules/monitoring/outputs.tf`

Outputs: `amp_workspace_id`, `amp_remote_write_endpoint`, `amg_workspace_id`, `amg_workspace_url`, `amg_service_account_token` (sensitive).

### Modified: `infra/modules/ecs/variables.tf`

Added `amp_remote_write_endpoint` variable (string, default empty).

### Modified: `infra/modules/ecs/main.tf`

- ADOT sidecar container added conditionally when `amp_remote_write_endpoint` is non-empty
- ADOT config: Prometheus receiver scraping `localhost:8080/actuator/prometheus` every 15s, `prometheusremotewrite` exporter with SigV4 auth
- `aps:RemoteWrite` IAM policy added to ECS task role (conditional)

### Modified: `infra/main.tf`

Added `module.monitoring` and wired `amp_remote_write_endpoint` to ECS module.

### Modified: `infra/variables.tf`

Added `grafana_admin_email` variable.

### Modified: `infra/environments/prod.tfvars`

Added `grafana_admin_email = "matt@emerald-grove.dev"`.

### Modified: `infra/outputs.tf`

Added `amp_workspace_id` and `amg_workspace_url` outputs.

### Modified: `infra/modules/identity/main.tf`

Added `aps:*`, `grafana:*`, `identitystore:*User*`, and `sso:DescribeRegisteredRegions` permissions to Tofu IAM role.

## Note

`tofu plan` requires AWS credentials and the S3 state backend. The full plan will be captured in Task 4.0 during deployment.
