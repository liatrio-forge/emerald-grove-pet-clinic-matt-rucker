# 14-spec-cd-pipeline

## Introduction/Overview

The Emerald Grove Veterinary Clinic has a CI pipeline (Spec 12) that builds, tests, and creates container images, and AWS infrastructure definitions (Spec 13) that can provision a full environment. But there's no deployment automation — the CI pipeline builds an image and stops. This spec connects the pieces: Dagger deploy functions that push to ECR and update ECS Fargate, a GHA workflow that deploys on merge to main, environment consolidation to a single prod environment, the first actual `tofu apply` to create real AWS resources, and a full teardown automation for cleanup.

## Goals

- Add Dagger deploy functions (ECR login, push, ECS force-deploy) and wire them into the CI pipeline
- Update GHA `ci.yml` to deploy automatically on merge to main using OIDC authentication
- Consolidate to a single prod environment (remove staging.tfvars)
- Apply the infrastructure and verify the application runs end-to-end on the ALB URL
- Create a `mise run teardown` task that fully destroys all AWS resources including the state backend
- Document the complete deployment and teardown lifecycle

## User Stories

- **As a developer**, I want my code to deploy automatically when I merge to main so that I get immediate feedback on whether it works in production.
- **As a DevOps engineer**, I want a single `mise run teardown -- --confirm` command so that I can cleanly destroy all AWS resources when I'm done with the exercise.
- **As a learner**, I want to see the full CI/CD flow working end-to-end (code push → build → test → image → deploy → live URL) so that I understand how all the pieces connect.

## Demoable Units of Work

### Unit 1: Environment Consolidation and Infrastructure Apply

**Purpose:** Consolidate to a single prod environment, apply the OpenTofu infrastructure to create real AWS resources, and verify they exist.

**Functional Requirements:**

- The `infra/environments/staging.tfvars` file shall be deleted
- The `infra/environments/prod.tfvars` file shall be the sole environment configuration
- The `.mise.toml` `tofu:plan` task shall be updated to use `prod.tfvars`
- Running `tofu -chdir=infra apply -var-file=environments/prod.tfvars` shall create all AWS resources: VPC, subnets, ALB, ECR, ECS cluster/service, RDS, Secrets Manager secrets, IAM roles, OIDC provider
- The `infra/outputs.tf` values shall be captured (ALB DNS name, ECR URL, ECS cluster/service names, CI role ARN)

**Proof Artifacts:**

- CLI: `tofu -chdir=infra apply` completes with 35 resources created
- CLI: `aws ecr describe-repositories` shows the ECR repository exists
- CLI: `aws ecs describe-clusters` shows the ECS cluster exists
- CLI: `tofu -chdir=infra output alb_dns_name` returns the ALB URL

### Unit 2: Dagger Deploy Functions and First Deployment

**Purpose:** Add deploy functions to the Dagger pipeline that authenticate with ECR, push the container image, and force a new ECS deployment. Execute the first deployment to get the application running.

**Functional Requirements:**

- The Dagger module shall expose a `Deploy` function that:
  - Authenticates with ECR using AWS credentials from the environment
  - Pushes the built container image to the ECR repository URL with git SHA tag
  - Forces a new ECS deployment by updating the service
- The Dagger `Run` function shall call `Deploy` after image build when a registry is provided
- The `mise run ci` task shall be updated to include deploy when the `DEPLOY=true` environment variable is set (or when `--registry` is provided)
- A `mise run deploy` task shall be created for manual deployments
- The first image shall be pushed to ECR and the ECS service shall start successfully
- The application shall be accessible via the ALB DNS name and return HTTP 200 on `/actuator/health`

**Proof Artifacts:**

- CLI: `mise run deploy` pushes an image to ECR and updates ECS, demonstrating the deploy function works
- CLI: `curl http://<alb-dns>/actuator/health` returns `{"status":"UP"}` from the live deployment
- CLI: `curl http://<alb-dns>/` returns HTTP 200, demonstrating the full application is serving

### Unit 3: GitHub Actions CD Workflow

**Purpose:** Update the GHA workflow to deploy automatically on merge to main using OIDC to assume the CI IAM role.

**Functional Requirements:**

- The `.github/workflows/ci.yml` shall be updated to:
  - Add `id-token: write` permission for OIDC
  - On push to main: run CI pipeline then deploy (build → test → image → push → ECS update)
  - On pull requests: run CI pipeline only (no deploy)
  - Use the `aws-actions/configure-aws-credentials` action with OIDC to assume the CI role
  - Pass the ECR registry URL and AWS region to the Dagger pipeline
- The workflow shall remain a thin wrapper — deploy logic lives in Dagger, not in YAML
- The workflow YAML shall contain no AWS CLI commands, ECS update commands, or ECR login commands — only Dagger invocation

**Proof Artifacts:**

- Diff: `ci.yml` shows OIDC permissions, AWS credentials action, and deploy step on main-only
- Diff: No AWS CLI commands in the workflow — all logic in Dagger

### Unit 4: Teardown Automation

**Purpose:** Create a complete teardown automation that destroys all AWS resources, empties the state bucket, and destroys the bootstrap resources, leaving only the IAM user.

**Functional Requirements:**

- A `mise run teardown` task shall be created that requires a `--confirm` flag
- Without `--confirm`, the task shall print what would be destroyed and exit without making changes
- With `--confirm`, the task shall execute in order:
  1. `tofu -chdir=infra destroy -var-file=environments/prod.tfvars -auto-approve` (destroy all infrastructure)
  2. `aws s3 rm s3://emerald-grove-tfstate --recursive` (empty the state bucket)
  3. `tofu -chdir=infra/bootstrap destroy -var='state_bucket_name=emerald-grove-tfstate' -var='lock_table_name=emerald-grove-tflock' -auto-approve` (destroy state backend)
- The teardown task shall handle the case where infrastructure doesn't exist (idempotent)
- The `docs/BOOTSTRAP.md` shall be updated with the teardown procedure
- After teardown, the only AWS resource remaining shall be the IAM user used for CLI access

**Proof Artifacts:**

- CLI: `mise run teardown` (without --confirm) prints the destruction plan and exits
- CLI: `mise run teardown -- --confirm` destroys all resources successfully
- CLI: `aws ecs describe-clusters` shows no clusters after teardown
- CLI: `aws s3 ls | grep emerald-grove` shows no buckets after teardown

## Non-Goals (Out of Scope)

1. **Automated rollback** — revert the commit and let CI redeploy. No ECS circuit breaker config.
2. **Blue/green or canary deployments** — single service, in-place update.
3. **Multiple environments** — single prod only. Staging can be added later via tfvars.
4. **Monitoring/alerting** — covered in Spec 15.
5. **Security scanning** — covered in Spec 16.
6. **DNS/HTTPS** — access via ALB DNS name over HTTP.

## Design Considerations

No specific design requirements identified. This is infrastructure/deployment work with no UI impact.

## Repository Standards

- Follow conventional commits: `feat(cd): ...` for deployment code, `chore(infra): ...` for config
- Dagger deploy functions in `dagger/main.go` alongside existing CI functions
- GHA workflow remains thin — all logic in Dagger per Constitution Article 11
- OpenTofu conventions per Constitution Article 12
- Teardown script follows defensive coding (check before destroy, handle missing resources)

## Technical Considerations

- **Dagger ECR authentication**: The Dagger pipeline needs AWS credentials to push to ECR. Locally, use `~/.aws/credentials`. In GHA, use OIDC via `aws-actions/configure-aws-credentials@v4` which sets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` as environment variables. Dagger can pass these as secrets.
- **ECS force deploy**: After pushing a new image, the ECS service needs to be told to pull the new image. This can be done via `aws ecs update-service --force-new-deployment` or by registering a new task definition revision with the new image tag.
- **Dagger + AWS SDK**: Dagger functions can execute AWS CLI commands inside a container, or use the AWS SDK directly in Go. The simpler approach is to run `aws` commands inside an AWS CLI container.
- **First deploy sequence**: `tofu apply` → ECS service created (fails, no image) → `mise run deploy` → image pushed to ECR → ECS pulls image → service healthy → ALB serves traffic.
- **GHA OIDC**: The `aws-actions/configure-aws-credentials` action handles OIDC token exchange transparently. The CI role ARN is passed as an input. No access keys stored in GitHub.
- **Teardown ordering**: Must destroy infra before bootstrap. If infra state is in S3 and we destroy S3 first, we lose the state file and can't destroy infra. Order matters.

## Security Considerations

- **No AWS credentials in code or workflow YAML**: OIDC handles GHA auth. Local auth uses `~/.aws/credentials`.
- **CI role is scoped**: Can only push to ECR and deploy to ECS. Cannot create/destroy infrastructure.
- **Teardown requires explicit confirmation**: `--confirm` flag prevents accidental destruction.
- **Proof artifacts**: `tofu output` may contain ALB DNS names and ARNs but no secrets. ECR URLs are not sensitive. Safe to commit.

## Success Metrics

1. **End-to-end deployment works**: merge to main → CI → deploy → app live on ALB URL
2. **ALB returns healthy app**: `/actuator/health` returns UP, homepage returns 200
3. **Teardown is complete**: after `mise run teardown -- --confirm`, zero AWS resources remain (except IAM user)
4. **GHA workflow is thin**: deploy logic in Dagger, no AWS commands in YAML
5. **Single environment**: only `prod.tfvars` exists, no staging references

## Open Questions

No open questions at this time.
