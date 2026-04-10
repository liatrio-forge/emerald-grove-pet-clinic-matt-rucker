# DevOps Capabilities Roadmap

> Roadmap for infrastructure, CI/CD, monitoring, security, and developer experience improvements.
> Each spec follows the SDD workflow: SDD-1 → SDD-2 → analyze → SDD-3 → SDD-4.

## Key Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Cloud provider | AWS | Admin access available, portfolio target |
| Container runtime | Podman | FOSS (Apache 2.0), rootless, native Linux, no Docker licensing |
| IaC tool | OpenTofu | FOSS (MPL 2.0), native state encryption, drop-in Terraform replacement |
| CI/CD engine | Dagger | Containerized pipelines, identical local and CI execution |
| Task runner / tool mgmt | Mise | Tool versions, env vars, task runner in one `.mise.toml` |
| CI trigger | GitHub Actions | Thin wrapper only — `mise run ci`, no logic in YAML |
| Orchestration | ECS Fargate | No Kubernetes — simple, serverless containers |
| Database (cloud) | RDS PostgreSQL | Managed, "the right way" for a real app |
| Metrics | Amazon Managed Prometheus (AMP) | Cloud-native, foundation for capstone |
| Dashboards | Amazon Managed Grafana (AMG) | Cloud-native, pairs with AMP |
| Logs | CloudWatch Logs | Native AWS, simple |
| Anomaly detection | CloudWatch Anomaly Detection | Per-metric ML, built-in |
| Vulnerability scanning | Grype (CI) + AWS Inspector (ECR) | Grype for SBOM in pipeline, Inspector for images |
| Environments | Staging + Prod | Dev is local only |
| Alerts | Not in scope | Learning exercise — skip for simplicity |

## Constitution Amendments

- **Article 11: Mise + Dagger CI/CD** — All pipeline logic in Dagger, invoked via Mise tasks. GHA is a thin trigger. Podman as container runtime.
- **Article 12: Infrastructure as Code** — All infra in OpenTofu. Remote state with locking. No manual console changes. No secrets in code.

## Spec Execution Order

### Spec 11: Production Containerization

- **Status:** Not started
- **Directory:** `docs/specs/11-spec-production-containerization/`
- **Scope:** Multi-stage Containerfile (Podman-compatible), optimized Spring Boot image, GHCR/ECR-ready
- **Depends on:** Nothing

### Spec 12: Dagger CI Pipeline + Mise Setup

- **Status:** Not started
- **Directory:** `docs/specs/12-spec-dagger-ci-pipeline/`
- **Scope:** `.mise.toml` (tool versions, tasks), Dagger pipeline (build → test → coverage gate → image build/push to ECR), thin GHA trigger workflow
- **Depends on:** Spec 11

### Spec 13: OpenTofu Foundation

- **Status:** Not started
- **Directory:** `docs/specs/13-spec-opentofu-foundation/`
- **Scope:** VPC, ECR, ECS Fargate, RDS PostgreSQL, IAM, security groups — staging + prod environments. S3 + DynamoDB state backend. Single module with tfvars per environment.
- **Depends on:** Spec 11

### Spec 14: CD Pipeline (Deploy)

- **Status:** Not started
- **Directory:** `docs/specs/14-spec-cd-pipeline/`
- **Scope:** Dagger deploy functions (push to ECR → update ECS Fargate service). Staging deploy on merge to main. Prod deploy on git tag. Manual approval gate for prod.
- **Depends on:** Specs 12, 13

### Spec 15: Monitoring & Observability

- **Status:** Not started
- **Directory:** `docs/specs/15-spec-monitoring-observability/`
- **Scope:** Micrometer integration in Spring Boot → AMP. AMG dashboards (latency, error rate, throughput, JVM metrics). CloudWatch Logs aggregation. CloudWatch Anomaly Detection on key metrics. OpenTofu for AMP/AMG/CloudWatch resources.
- **Depends on:** Specs 13, 14

### Spec 16: Security Scanning

- **Status:** Not started
- **Directory:** `docs/specs/16-spec-security-scanning/`
- **Scope:** Grype integration in Dagger pipeline (scan CycloneDX SBOM). AWS Inspector enabled on ECR repos. Fail pipeline on critical/high vulnerabilities.
- **Depends on:** Spec 12

### Spec 17: Dev Environment & Lean Tooling

- **Status:** Not started
- **Directory:** `docs/specs/17-spec-dev-environment/`
- **Scope:** One-command `mise run dev` setup (install tools, start Podman Compose postgres, run Spring Boot). Pre-commit hook auto-install. Developer onboarding documentation. Remove Tilt dependency.
- **Depends on:** Spec 12

### Capstone: AI-Powered Platform Engineering Tool

- **Status:** Not started
- **Directory:** `docs/specs/20-spec-ai-platform-tool/`
- **Scope:** Separate internal-only interface (not the user-facing pet clinic assistant). Queries AMP/AMG/CloudWatch. AI-driven operational insights. Distinct security boundary from the application.
- **Depends on:** Spec 15

## Dependency Graph

```text
Spec 11 (Containerization)
  ├── Spec 12 (Dagger CI + Mise)
  │     ├── Spec 14 (CD Pipeline) ← also needs Spec 13
  │     ├── Spec 16 (Security Scanning)
  │     └── Spec 17 (Dev Environment)
  └── Spec 13 (OpenTofu Foundation)
        ├── Spec 14 (CD Pipeline) ← also needs Spec 12
        └── Spec 15 (Monitoring) ← also needs Spec 14
              └── Capstone (AI Platform Tool)
```

## Execution Sequence

1. Spec 11 → 2. Spec 12 → 3. Spec 13 → 4. Spec 14 → 5. Spec 15 → 6. Spec 16 → 7. Spec 17 → 8. Capstone

Specs 16 and 17 can run in parallel after Spec 12 if desired.
