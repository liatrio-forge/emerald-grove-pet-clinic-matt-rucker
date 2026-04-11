# 14-tasks-cd-pipeline

Task list for [14-spec-cd-pipeline](14-spec-cd-pipeline.md).

## Relevant Files

- `infra/environments/staging.tfvars` - **Delete.** Consolidating to single prod environment.
- `infra/environments/prod.tfvars` - **Existing.** Sole environment config.
- `.mise.toml` - **Modify.** Update tofu:plan to use prod, add deploy and teardown tasks.
- `dagger/main.go` - **Modify.** Add Deploy function, update Run to include deploy, add ECR auth.
- `.github/workflows/ci.yml` - **Modify.** Add OIDC, AWS credentials, deploy-on-main.
- `docs/BOOTSTRAP.md` - **Modify.** Add teardown procedure.
- `scripts/teardown.sh` - **New file.** Teardown script with --confirm safety.
- `docs/specs/14-spec-cd-pipeline/14-proofs/` - **New directory.** Proof artifact outputs.

### Notes

- This spec creates and destroys real AWS resources. Expect troubleshooting during Task 2.0.
- Use `mise exec -- <command>` for all tool invocations in Claude Code's shell.
- Capture `tofu output` values after apply — they're needed for deploy functions.
- The first ECS deployment will fail until an image is pushed (expected, documented).
- Follow conventional commits: `feat(cd): ...` for deployment code.

## Tasks

### [~] 1.0 Environment Consolidation and Infrastructure Apply

Delete staging.tfvars, update mise tofu:plan to use prod.tfvars, and run `tofu apply` to create all AWS resources. Capture outputs (ALB DNS, ECR URL, CI role ARN). Verify resources exist in AWS.

#### 1.0 Proof Artifact(s)

- CLI: `tofu -chdir=infra apply` completes successfully, demonstrating all 35 resources are created
- CLI: `tofu -chdir=infra output` shows ALB DNS name, ECR URL, ECS cluster/service, CI role ARN
- CLI: `aws ecr describe-repositories` shows the ECR repository exists
- CLI: `aws ecs describe-clusters` shows the ECS cluster exists (service will be unhealthy — no image yet, expected)

#### 1.0 Tasks

- [ ] 1.1 Delete `infra/environments/staging.tfvars`.
- [ ] 1.2 Update `.mise.toml` `tofu:plan` task to use `prod.tfvars` instead of `staging.tfvars`.
- [ ] 1.3 Initialize infra with remote backend: `tofu -chdir=infra init -backend-config=bucket=emerald-grove-tfstate -backend-config=dynamodb_table=emerald-grove-tflock`.
- [ ] 1.4 Run `tofu -chdir=infra plan -var-file=environments/prod.tfvars` and verify 35 resources will be created (no errors).
- [ ] 1.5 Run `tofu -chdir=infra apply -var-file=environments/prod.tfvars` to create all AWS resources. This will take several minutes (RDS is the slowest, ~5-10 minutes).
- [ ] 1.6 Capture outputs: run `tofu -chdir=infra output -json` and save key values (alb_dns_name, ecr_repository_url, ecs_cluster_name, ecs_service_name, ci_role_arn, tofu_role_arn). These are needed for subsequent tasks.
- [ ] 1.7 Verify resources in AWS:
  - `aws ecr describe-repositories --query 'repositories[].repositoryUri'` shows ECR repo
  - `aws ecs describe-clusters --clusters <cluster-name>` shows ACTIVE cluster
  - `aws ecs describe-services --cluster <cluster-name> --services <service-name>` shows service (will have 0 running tasks — expected, no image yet)
  - `aws rds describe-db-instances --query 'DBInstances[].Endpoint'` shows RDS endpoint
  - `curl http://<alb-dns>/` returns 503 (no healthy targets — expected)
- [ ] 1.8 Save proof artifact output to `docs/specs/14-spec-cd-pipeline/14-proofs/14-task-01-proofs.md`

### [ ] 2.0 Dagger Deploy Functions and First Deployment

Add `Deploy` function to Dagger that authenticates with ECR, pushes the image, and forces an ECS redeployment. Create `mise run deploy` task. Execute the first deployment: push image to ECR, ECS service starts, app accessible on ALB URL.

#### 2.0 Proof Artifact(s)

- CLI: `mise run deploy` pushes image to ECR and triggers ECS deployment
- CLI: `curl http://<alb-dns>/actuator/health` returns `{"status":"UP"}` from the live deployment
- CLI: `curl -s -o /dev/null -w '%{http_code}' http://<alb-dns>/` returns 200, demonstrating the application is serving pages

#### 2.0 Tasks

- [ ] 2.1 Update `dagger/main.go`: refactor the existing `Push` function to work with ECR. The deploy flow is:
  1. Build the image using `BuildImage`
  2. Get the ECR registry URL (passed as parameter)
  3. Get the git SHA for tagging
  4. Use Dagger's `Container.WithRegistryAuth()` to authenticate with ECR (credentials from environment)
  5. Publish the image to `<ecr-url>:<sha>`
  - Note: ECR auth requires AWS credentials. Dagger can pick up `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` from the environment. For ECR, we need to get the auth token via `aws ecr get-login-password` and pass it to `WithRegistryAuth`.
- [ ] 2.2 Add an `EcsForceDeployment` function to `dagger/main.go` that runs `aws ecs update-service --cluster <cluster> --service <service> --force-new-deployment` inside an AWS CLI container. Accept cluster name and service name as parameters.
- [ ] 2.3 Update the `Run` function: when `registry` is provided, after building the image call the deploy functions (push to ECR + force ECS deployment). Accept additional parameters for `awsRegion`, `ecsCluster`, and `ecsService`.
- [ ] 2.4 Add a `mise run deploy` task to `.mise.toml` that calls the Dagger pipeline with the registry URL and ECS details from `tofu output`. The task should read values from tofu output or accept them as environment variables.
- [ ] 2.5 Execute the first deployment:
  - Run `mise run deploy` (or the equivalent dagger call with registry/cluster/service params)
  - Watch ECR for the pushed image: `aws ecr list-images --repository-name <repo>`
  - Watch ECS service for task startup: `aws ecs describe-services --cluster <cluster> --services <service>` — wait for runningCount=1
  - This is where troubleshooting is most likely needed (ECR auth, task role permissions, RDS connectivity, health check failures)
- [ ] 2.6 Verify the application is live:
  - `curl http://<alb-dns>/actuator/health` — expect `{"status":"UP"}`
  - `curl http://<alb-dns>/` — expect HTTP 200
  - If the health check fails, check ECS task logs: `aws logs get-log-events --log-group-name /ecs/emerald-grove-prod --log-stream-name <stream>`
- [ ] 2.7 Save proof artifact output to `docs/specs/14-spec-cd-pipeline/14-proofs/14-task-02-proofs.md`

### [ ] 3.0 GitHub Actions CD Workflow

Update `ci.yml` to add OIDC permissions, AWS credential configuration, and deploy-on-main logic. On push to main: CI + deploy. On PR: CI only. All deploy logic stays in Dagger.

#### 3.0 Proof Artifact(s)

- Diff: `ci.yml` shows OIDC `id-token: write` permission, `aws-actions/configure-aws-credentials`, and deploy step gated on `github.ref == 'refs/heads/main'`
- Diff: No AWS CLI commands in the workflow YAML — all deploy logic in Dagger

#### 3.0 Tasks

- [ ] 3.1 Update `.github/workflows/ci.yml`:
  - Add `permissions: id-token: write, contents: read` at the job level (required for OIDC)
  - Add a step after `mise run ci` that configures AWS credentials using `aws-actions/configure-aws-credentials@v4` with `role-to-assume` set to the CI role ARN and `aws-region: us-east-1`
  - Add a deploy step gated on `if: github.ref == 'refs/heads/main' && github.event_name == 'push'` that runs the Dagger deploy command with the ECR registry URL, ECS cluster, and service name
  - Keep the upload-artifact step at the end
  - The workflow should remain under 30 lines of meaningful YAML
- [ ] 3.2 Verify: read the workflow and confirm no AWS CLI commands, no `docker` commands, no `ecr get-login-password` — all deploy logic is in Dagger.
- [ ] 3.3 Save proof artifact output to `docs/specs/14-spec-cd-pipeline/14-proofs/14-task-03-proofs.md`

### [ ] 4.0 Teardown Automation and Documentation

Create `mise run teardown` task with `--confirm` safety flag. Without flag: print what would be destroyed. With flag: destroy infra, empty S3, destroy bootstrap. Update BOOTSTRAP.md with teardown procedure. Execute teardown and verify zero resources remain.

#### 4.0 Proof Artifact(s)

- CLI: `mise run teardown` (without --confirm) prints destruction plan and exits safely
- CLI: `mise run teardown -- --confirm` destroys all resources successfully
- CLI: `aws ecs list-clusters` shows no clusters after teardown
- CLI: `aws s3 ls | grep emerald-grove` shows no buckets after teardown

#### 4.0 Tasks

- [ ] 4.1 Create `scripts/teardown.sh`:
  - Check for `--confirm` flag. Without it, print what would be destroyed (list of resources) and exit 0.
  - With `--confirm`, execute in order:
    1. `tofu -chdir=infra destroy -var-file=environments/prod.tfvars -auto-approve`
    2. `aws s3 rm s3://emerald-grove-tfstate --recursive`
    3. `tofu -chdir=infra/bootstrap destroy -var='state_bucket_name=emerald-grove-tfstate' -var='lock_table_name=emerald-grove-tflock' -auto-approve`
  - Handle errors gracefully (if infra doesn't exist, skip to next step)
  - Print summary of what was destroyed
- [ ] 4.2 Add `mise run teardown` task to `.mise.toml` that runs `scripts/teardown.sh` and passes through arguments.
- [ ] 4.3 Update `docs/BOOTSTRAP.md`: add a "Complete Teardown" section referencing `mise run teardown -- --confirm` with explanation of what gets destroyed and what remains (IAM user only).
- [ ] 4.4 Test dry run: run `mise run teardown` (without --confirm) and verify it prints the plan and exits without destroying anything.
- [ ] 4.5 Execute teardown: run `mise run teardown -- --confirm` and verify all resources are destroyed:
  - `aws ecs list-clusters` — no clusters
  - `aws ecr describe-repositories` — no repositories
  - `aws rds describe-db-instances` — no instances
  - `aws s3 ls | grep emerald-grove` — no buckets
  - `aws dynamodb list-tables | grep emerald-grove` — no tables
- [ ] 4.6 Save proof artifact output to `docs/specs/14-spec-cd-pipeline/14-proofs/14-task-04-proofs.md`
