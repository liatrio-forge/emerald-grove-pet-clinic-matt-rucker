# 15-spec-monitoring-observability

## Introduction/Overview

The Emerald Grove Veterinary Clinic has CI/CD and infrastructure but no observability. CloudWatch Logs exist (from ECS), but there are no metrics, no dashboards, and no way to understand application health beyond checking `/actuator/health`. This spec adds Amazon Managed Prometheus (AMP) for metrics storage, Amazon Managed Grafana (AMG) for dashboards, and an ADOT (AWS Distro for OpenTelemetry) sidecar to collect Prometheus metrics from Spring Boot. This forms the foundation for the AI-powered Platform Engineering capstone.

## Goals

- Add Micrometer Prometheus metrics export to the Spring Boot application
- Deploy an ADOT sidecar in the ECS task to scrape metrics and remote-write to AMP
- Create an AMP workspace and AMG workspace via OpenTofu
- Provision a Grafana dashboard (as code) showing latency, error rate, throughput, and JVM metrics
- Configure AMG with IAM Identity Center authentication
- Verify end-to-end: app running → metrics in AMP → visible in AMG dashboard

## User Stories

- **As a DevOps engineer**, I want to see application metrics (latency, error rate, throughput) in a Grafana dashboard so that I can monitor the health of the deployed application.
- **As a developer**, I want JVM metrics (heap usage, GC, threads) visible in Grafana so that I can diagnose performance issues.
- **As a platform engineer**, I want metrics stored in AMP so that the AI Platform Engineering capstone can query them programmatically.

## Demoable Units of Work

### Unit 1: Spring Boot Micrometer + Prometheus Metrics

**Purpose:** Configure the Spring Boot application to expose Prometheus-formatted metrics at `/actuator/prometheus` so the ADOT sidecar can scrape them.

**Functional Requirements:**

- The `pom.xml` shall include the `micrometer-registry-prometheus` dependency
- The Spring Boot application shall expose a `/actuator/prometheus` endpoint that returns Prometheus-format metrics
- The metrics shall include: HTTP request duration (by method, status, URI), JVM heap memory usage, JVM GC metrics, active thread count, HikariCP connection pool metrics
- The `/actuator/prometheus` endpoint shall be accessible without authentication (within the ECS task network)

**Proof Artifacts:**

- CLI: `curl http://localhost:8080/actuator/prometheus` returns Prometheus-format metrics when running locally
- CLI: Metrics output includes `http_server_requests_seconds`, `jvm_memory_used_bytes`, `hikaricp_connections_active`

### Unit 2: OpenTofu Monitoring Module (AMP + AMG)

**Purpose:** Create OpenTofu resources for AMP workspace, AMG workspace with IAM Identity Center auth, and IAM roles for the ADOT sidecar to write to AMP.

**Functional Requirements:**

- An `infra/modules/monitoring/` module shall create:
  - An AMP workspace (named `emerald-grove-{environment}`)
  - An AMG workspace with IAM Identity Center (AWS SSO) authentication, Grafana version 10+
  - An IAM role for AMG to read from AMP (data source permissions)
  - An AMG data source configuration pointing to the AMP workspace
  - An IAM Identity Center user (via `aws_identitystore_user`) for Grafana access
  - An AMG role association granting the Identity Center user `ADMIN` access to the workspace
- The `infra/modules/ecs/` module shall be updated to:
  - Add an ADOT sidecar container to the ECS task definition (image: `public.ecr.aws/aws-observability/aws-otel-collector:latest`)
  - The ADOT container shall scrape `localhost:8080/actuator/prometheus` and remote-write to the AMP endpoint
  - The ADOT container shall use the ECS task role for AMP authentication (SigV4)
  - The task role shall have `aps:RemoteWrite` permission on the AMP workspace
- The ADOT collector configuration shall be passed as an environment variable or SSM parameter

**Proof Artifacts:**

- CLI: `tofu -chdir=infra plan -var-file=environments/prod.tfvars` shows AMP workspace, AMG workspace, ADOT sidecar in task definition
- CLI: `tofu -chdir=infra apply` creates the monitoring resources

### Unit 3: Grafana Dashboard and End-to-End Verification

**Purpose:** Deploy a Grafana dashboard as code showing the 4 key panels, assign a user in IAM Identity Center to AMG, and verify metrics flow from app → ADOT → AMP → AMG.

**Functional Requirements:**

- An `aws_grafana_dashboard` resource in OpenTofu shall provision a dashboard with 4 panels:
  1. Request Latency (p50, p95, p99) — `http_server_requests_seconds` histogram
  2. Error Rate — `http_server_requests_seconds_count` filtered by status >= 500
  3. Throughput — `rate(http_server_requests_seconds_count[5m])`
  4. JVM Heap Usage — `jvm_memory_used_bytes{area="heap"}`
- An IAM Identity Center user shall be assigned to the AMG workspace with `ADMIN` role
- After deploying, the AMG dashboard URL shall be accessible and showing live data
- The dashboard JSON shall be stored in the repo (e.g., `infra/dashboards/overview.json`)

**Proof Artifacts:**

- CLI: `tofu apply` creates the dashboard
- CLI: `awscurl` or Grafana API query to AMP shows metrics present
- URL: AMG dashboard URL showing live panels with data from the running application

## Non-Goals (Out of Scope)

1. **CloudWatch Anomaly Detection** — deferred, can be added later
2. **Alerting / SNS notifications** — no alerts for a learning exercise
3. **Distributed tracing (X-Ray)** — metrics only, no traces
4. **Custom business metrics** — only standard Spring Boot / JVM / HTTP metrics
5. **Log aggregation beyond CloudWatch** — ECS already sends logs to CloudWatch, no changes needed
6. **Multiple dashboards** — single overview dashboard only

## Design Considerations

No specific design requirements identified. The Grafana dashboard layout follows standard observability patterns (USE/RED methodology).

## Repository Standards

- Follow conventional commits: `feat(monitoring): ...` for monitoring code
- OpenTofu monitoring module in `infra/modules/monitoring/`
- Dashboard JSON in `infra/dashboards/`
- Follow Constitution Article 12 (IaC) — all monitoring resources in OpenTofu
- Follow Constitution Article 12 teardown rules — monitoring resources must destroy cleanly

## Technical Considerations

- **ADOT sidecar image**: `public.ecr.aws/aws-observability/aws-otel-collector:latest` — AWS-maintained, ~128MB
- **ADOT configuration**: The collector needs a config file specifying the Prometheus scrape target (`localhost:8080/actuator/prometheus`) and the AMP remote write endpoint. This config can be passed as an environment variable (`AOT_CONFIG_CONTENT`) or stored in SSM Parameter Store.
- **AMP remote write endpoint**: Format is `https://aps-workspaces.{region}.amazonaws.com/workspaces/{workspace_id}/api/v1/remote_write`. The ADOT collector authenticates via SigV4 using the ECS task role.
- **AMG + IAM Identity Center**: The AMG workspace needs `authentication_providers = ["AWS_SSO"]`. The AWS provider supports `aws_grafana_workspace` and `aws_grafana_role_association` resources. The user must exist in IAM Identity Center first.
- **Micrometer Prometheus**: Add `io.micrometer:micrometer-registry-prometheus` to `pom.xml`. Spring Boot auto-configures the `/actuator/prometheus` endpoint when this dependency is present. No application code changes needed.
- **Grafana dashboard as code**: The `aws_grafana_dashboard` resource accepts a JSON model. We store the JSON in `infra/dashboards/overview.json` and reference it via `file()` in OpenTofu.
- **ECS task definition changes**: Adding the ADOT sidecar means the task definition gets a second container. Both containers share the network namespace (awsvpc mode), so `localhost` works for scraping.

## Security Considerations

- **AMP write**: ADOT authenticates via SigV4 using the ECS task role — no API keys needed
- **AMG access**: IAM Identity Center controls who can view dashboards — no anonymous access
- **AMP read**: AMG reads from AMP via an IAM role with `aps:QueryMetrics` permission
- **No secrets in OpenTofu**: AMP/AMG don't require API keys — all IAM-based
- **Proof artifacts**: AMG workspace URL and AMP workspace ID are not sensitive — safe to commit

## Success Metrics

1. **`/actuator/prometheus` returns metrics** when the app runs locally
2. **AMP workspace has metrics** within 2 minutes of deployment
3. **AMG dashboard shows 4 live panels** with data from the running application
4. **All monitoring resources in OpenTofu** — no manual console changes
5. **Teardown cleans up monitoring resources** — `tofu destroy` removes AMP, AMG, dashboard

## Open Questions

No open questions at this time. IAM Identity Center user will be created and torn down via OpenTofu using `aws_identitystore_user` and `aws_grafana_role_association` resources.
