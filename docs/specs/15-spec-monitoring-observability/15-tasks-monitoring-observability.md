# 15-tasks-monitoring-observability

Task list for [15-spec-monitoring-observability](15-spec-monitoring-observability.md).

## Relevant Files

- `pom.xml` - **Modify.** Add micrometer-registry-prometheus dependency.
- `src/main/resources/application.properties` - **Modify.** Ensure prometheus endpoint is enabled.
- `infra/modules/monitoring/main.tf` - **New file.** AMP workspace, AMG workspace, Identity Center user, IAM roles.
- `infra/modules/monitoring/variables.tf` - **New file.** Monitoring module inputs.
- `infra/modules/monitoring/outputs.tf` - **New file.** Monitoring module outputs (AMP endpoint, AMG URL).
- `infra/modules/ecs/main.tf` - **Modify.** Add ADOT sidecar container, update task role for AMP write.
- `infra/modules/ecs/variables.tf` - **Modify.** Add AMP remote write endpoint variable.
- `infra/main.tf` - **Modify.** Wire monitoring module, pass AMP endpoint to ECS module.
- `infra/outputs.tf` - **Modify.** Add AMP workspace ID, AMG URL outputs.
- `infra/dashboards/overview.json` - **New file.** Grafana dashboard JSON (4 panels).
- `docs/specs/15-spec-monitoring-observability/15-proofs/` - **New directory.** Proof artifact outputs.

### Notes

- Use `mise exec -- <command>` for all tool invocations in Claude Code's shell.
- The ADOT sidecar image is `public.ecr.aws/aws-observability/aws-otel-collector:latest`.
- ADOT config is passed via `AOT_CONFIG_CONTENT` environment variable.
- AMG requires IAM Identity Center. Instance ID: `d-906787324a`.
- Follow conventional commits: `feat(monitoring): ...`.
- All monitoring resources must destroy cleanly per Constitution Article 12.

## Tasks

### [x] 1.0 Spring Boot Micrometer Prometheus Metrics

Add the Micrometer Prometheus registry dependency and verify `/actuator/prometheus` exposes metrics locally. No AWS or infra changes — app code only.

#### 1.0 Proof Artifact(s)

- CLI: `curl http://localhost:8080/actuator/prometheus` returns Prometheus-format metrics including `http_server_requests_seconds`, `jvm_memory_used_bytes`, `hikaricp_connections_active`
- CLI: `./mvnw test` passes (no regressions from adding the dependency)

#### 1.0 Tasks

- [x] 1.1 Add `io.micrometer:micrometer-registry-prometheus` dependency to `pom.xml` (under the existing actuator dependency, no version needed — managed by Spring Boot BOM).
- [x] 1.2 Verify the `/actuator/prometheus` endpoint is auto-configured by Spring Boot. The existing `management.endpoints.web.exposure.include=*` in `application.properties` already exposes all endpoints including prometheus. No config change needed.
- [x] 1.3 Start the app locally (`mise run dev` or `./mvnw spring-boot:run`) and verify: `curl http://localhost:8080/actuator/prometheus` returns Prometheus-format metrics. Confirm these metric names are present: `http_server_requests_seconds`, `jvm_memory_used_bytes`, `hikaricp_connections`.
- [x] 1.4 Run `./mvnw test` to confirm no regressions.
- [x] 1.5 Save proof artifact output to `docs/specs/15-spec-monitoring-observability/15-proofs/15-task-01-proofs.md`

### [x] 2.0 OpenTofu Monitoring Module (AMP, AMG, Identity Center)

Create `infra/modules/monitoring/` with AMP workspace, AMG workspace (IAM Identity Center auth), Identity Center user, AMG role association, AMG-to-AMP data source, and IAM roles. Update ECS task definition to add ADOT sidecar container with Prometheus scrape + AMP remote write config.

#### 2.0 Proof Artifact(s)

- CLI: `tofu -chdir=infra plan -var-file=environments/prod.tfvars` shows AMP workspace, AMG workspace, Identity Center user, ADOT sidecar in task definition
- CLI: `tofu validate` passes with all monitoring resources

#### 2.0 Tasks

- [x] 2.1 Create `infra/modules/monitoring/variables.tf` with inputs: `environment`, `project`, `identity_store_id` (default `d-906787324a`), `grafana_user_email`, `grafana_user_name`.
- [x] 2.2 Create `infra/modules/monitoring/main.tf` with:
  - `aws_prometheus_workspace` named `${var.project}-${var.environment}`
  - `aws_grafana_workspace` with `authentication_providers = ["AWS_SSO"]`, `permission_type = "SERVICE_MANAGED"`, `data_sources = ["PROMETHEUS"]`, Grafana version 10+
  - IAM role for AMG with trust policy for `grafana.amazonaws.com`, permissions to `aps:QueryMetrics`, `aps:GetMetricMetadata`, `aps:GetSeries`, `aps:GetLabels` on the AMP workspace
  - `aws_grafana_workspace_service_account` or `aws_grafana_role_association` to give AMG the AMP read role
  - `aws_identitystore_user` creating a user in IAM Identity Center (email and display name from variables)
  - `aws_grafana_role_association` granting the Identity Center user `ADMIN` role in AMG
- [x] 2.3 Create `infra/modules/monitoring/outputs.tf` exposing: `amp_workspace_id`, `amp_remote_write_endpoint`, `amg_workspace_url`, `amg_workspace_id`.
- [x] 2.4 Update `infra/modules/ecs/variables.tf`: add `amp_remote_write_endpoint` variable (string, optional, default empty).
- [x] 2.5 Update `infra/modules/ecs/main.tf`: when `amp_remote_write_endpoint` is non-empty, add a second container to the task definition — the ADOT sidecar:
  - Image: `public.ecr.aws/aws-observability/aws-otel-collector:latest`
  - Essential: false (app container is essential, sidecar is not)
  - Environment variable `AOT_CONFIG_CONTENT` containing the ADOT collector YAML config:
    - Receiver: `prometheus` scraping `localhost:8080/actuator/prometheus` every 15s
    - Exporter: `prometheusremotewrite` pointing to the AMP remote write endpoint with `auth.authenticator: sigv4auth` and `region`
    - Extensions: `sigv4auth` for SigV4 signing
    - Service pipeline: `metrics` from prometheus receiver to prometheusremotewrite exporter
  - Memory: 256 MB (separate from the app container's 2 GB)
  - Log configuration: awslogs driver to the same CloudWatch log group
- [x] 2.6 Update `infra/modules/ecs/main.tf`: add `aps:RemoteWrite` permission to the ECS task role (not task execution role) so the ADOT sidecar can write to AMP.
- [x] 2.7 Update `infra/main.tf`: add the monitoring module, pass `identity_store_id` and Grafana user details. Pass `amp_remote_write_endpoint` from monitoring module output to the ECS module.
- [x] 2.8 Update `infra/outputs.tf`: add `amp_workspace_id`, `amg_workspace_url`.
- [x] 2.9 Add `grafana_admin_email` variable to `infra/variables.tf` and `infra/environments/prod.tfvars`.
- [x] 2.10 Validate: `tofu -chdir=infra init` and `tofu -chdir=infra validate` pass. `tofu plan` shows AMP, AMG, Identity Center user, ADOT sidecar.
- [x] 2.11 Save proof artifact output to `docs/specs/15-spec-monitoring-observability/15-proofs/15-task-02-proofs.md`

### [x] 3.0 Grafana Dashboard as Code

Create the overview dashboard JSON (latency, error rate, throughput, JVM heap) and provision it via `aws_grafana_dashboard` in OpenTofu. Store dashboard JSON in `infra/dashboards/overview.json`.

#### 3.0 Proof Artifact(s)

- Diff: `infra/dashboards/overview.json` contains 4 panels (latency p50/p95/p99, error rate, throughput, JVM heap)
- CLI: `tofu plan` shows `aws_grafana_dashboard` resource will be created

#### 3.0 Tasks

- [x] 3.1 Create `infra/dashboards/overview.json` with a Grafana dashboard JSON containing 4 panels:
  - **Panel 1 — Request Latency**: Graph panel with `histogram_quantile(0.5, ...)`, `histogram_quantile(0.95, ...)`, `histogram_quantile(0.99, ...)` on `http_server_requests_seconds_bucket`
  - **Panel 2 — Error Rate**: Stat or graph panel with `sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) / sum(rate(http_server_requests_seconds_count[5m]))`
  - **Panel 3 — Throughput**: Graph panel with `sum(rate(http_server_requests_seconds_count[5m]))`
  - **Panel 4 — JVM Heap Usage**: Graph panel with `jvm_memory_used_bytes{area="heap"}` and `jvm_memory_max_bytes{area="heap"}`
  - All panels should use the AMP data source (referenced by name or UID)
  - Dashboard title: "Emerald Grove — Overview"
- [x] 3.2 Add dashboard provisioning to `infra/modules/monitoring/main.tf` using `terraform_data` + `local-exec` to call the Grafana HTTP API (the `grafana/grafana` provider can't reference resource attributes in provider config). Uses service account token for auth. Also creates AMP data source with SigV4 auth.
- [x] 3.3 Validate: `tofu validate` passes with the dashboard resource.
- [x] 3.4 Save proof artifact output to `docs/specs/15-spec-monitoring-observability/15-proofs/15-task-03-proofs.md`

### [x] 4.0 Deploy, Verify End-to-End, and Teardown

Bootstrap + apply infra, deploy the app (with Micrometer + ADOT sidecar), verify metrics flow into AMP and appear in AMG dashboard. Then teardown.

#### 4.0 Proof Artifact(s)

- CLI: `tofu apply` creates all monitoring resources (AMP, AMG, ADOT sidecar, dashboard)
- CLI: AMP query returns metrics (via awscurl or AWS CLI)
- URL: AMG dashboard URL showing live panels with data
- CLI: `mise run teardown -- --confirm` destroys everything cleanly

#### 4.0 Tasks

- [x] 4.1 Bootstrap state backend: `tofu -chdir=infra/bootstrap apply -auto-approve -var='state_bucket_name=emerald-grove-tfstate' -var='lock_table_name=emerald-grove-tflock'`
- [x] 4.2 Init and apply infrastructure: `tofu -chdir=infra init -backend-config=... && tofu -chdir=infra apply -var-file=environments/prod.tfvars -auto-approve`. Captured outputs (ALB DNS, AMP endpoint, AMG URL).
- [x] 4.3 Deploy the app (built and pushed with podman due to Dagger ECR auth issue). ADOT sidecar starts alongside the app. ECS task def has 2 containers.
- [x] 4.4 ECS service stabilized. ADOT sidecar logs confirm scraping `localhost:8080/actuator/prometheus` with SigV4 auth and writing to AMP.
- [x] 4.5 Verified metrics in AMP via `awscurl`: `up{job="spring-boot"}=1`, `http_server_requests_seconds_count`, `jvm_memory_used_bytes` all present.
- [x] 4.6 AMG dashboard URL: `https://g-668c15280e.grafana-workspace.us-east-1.amazonaws.com/d/emerald-grove-overview/`. AMP data source configured with SigV4. 4 panels (latency, error rate, throughput, JVM heap).
- [x] 4.7 Teardown: `mise run teardown -- --confirm`. 43 infrastructure + 5 bootstrap resources destroyed cleanly.
- [x] 4.8 Save proof artifact output to `docs/specs/15-spec-monitoring-observability/15-proofs/15-task-04-proofs.md`
