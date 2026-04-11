# 13-tasks-opentofu-foundation

Task list for [13-spec-opentofu-foundation](13-spec-opentofu-foundation.md).

## Relevant Files

- `.mise.toml` - **Modify.** Add `opentofu` tool version and `tofu:plan` task.
- `infra/bootstrap/main.tf` - **New file.** S3 bucket + DynamoDB table for state backend.
- `infra/bootstrap/variables.tf` - **New file.** Bootstrap input variables.
- `infra/bootstrap/outputs.tf` - **New file.** Bootstrap outputs (bucket name, table name).
- `infra/providers.tf` - **New file.** AWS provider config and S3 backend.
- `infra/main.tf` - **New file.** Root module composing all child modules.
- `infra/variables.tf` - **New file.** Root module input variables.
- `infra/outputs.tf` - **New file.** Root module outputs (ALB URL, ECR URL, etc.).
- `infra/modules/networking/main.tf` - **New file.** VPC, subnets, IGW, route tables, SGs, ALB.
- `infra/modules/networking/variables.tf` - **New file.** Networking module inputs.
- `infra/modules/networking/outputs.tf` - **New file.** Networking module outputs.
- `infra/modules/ecr/main.tf` - **New file.** ECR repository with lifecycle policy.
- `infra/modules/ecr/variables.tf` - **New file.** ECR module inputs.
- `infra/modules/ecr/outputs.tf` - **New file.** ECR module outputs.
- `infra/modules/rds/main.tf` - **New file.** RDS PostgreSQL, random password, Secrets Manager.
- `infra/modules/rds/variables.tf` - **New file.** RDS module inputs.
- `infra/modules/rds/outputs.tf` - **New file.** RDS module outputs.
- `infra/modules/ecs/main.tf` - **New file.** ECS cluster, task definition, service, IAM roles.
- `infra/modules/ecs/variables.tf` - **New file.** ECS module inputs.
- `infra/modules/ecs/outputs.tf` - **New file.** ECS module outputs.
- `infra/environments/staging.tfvars` - **New file.** Staging environment values.
- `infra/environments/prod.tfvars` - **New file.** Production environment values.
- `infra/README.md` - **New file.** Infrastructure documentation and usage.
- `docs/specs/13-spec-opentofu-foundation/13-proofs/` - **New directory.** Proof artifact outputs.

### Notes

- Use `tofu` CLI for all OpenTofu operations (not `terraform`).
- Follow HCL conventions: `main.tf`, `variables.tf`, `outputs.tf` per module.
- All resources must be tagged with `Environment`, `Project=emerald-grove`, `ManagedBy=opentofu`.
- No secrets in `.tf` files or `.tfvars` files. Database password generated via `random_password`.
- Proof artifacts are `tofu plan` output only — no `tofu apply` in this spec.
- Follow conventional commits: `feat(infra): ...` for infrastructure code.

## Tasks

### [x] 1.0 Mise Integration and State Backend Bootstrap

Add OpenTofu to `.mise.toml` and create the `infra/bootstrap/` config that provisions the S3 bucket and DynamoDB table for remote state. Add a `tofu:plan` task to Mise. Create `infra/README.md` documenting the bootstrap process.

#### 1.0 Proof Artifact(s)

- CLI: `mise ls` shows `opentofu` installed, demonstrating tool management works
- CLI: `tofu -chdir=infra/bootstrap init` succeeds, demonstrating bootstrap config is valid
- CLI: `tofu -chdir=infra/bootstrap plan` shows S3 bucket and DynamoDB table will be created
- Diff: `infra/README.md` documents the bootstrap process

#### 1.0 Tasks

- [x] 1.1 Add `opentofu = "latest"` to `.mise.toml` `[tools]` section. Run `mise install` to install it. Verify with `mise exec -- tofu version`.
- [x] 1.2 Add a `tofu:plan` task to `.mise.toml` that runs `tofu -chdir=infra plan -var-file=environments/staging.tfvars` (convenience task for quick plan checks).
- [x] 1.3 Create `infra/bootstrap/main.tf` with:
  - `terraform` block requiring `aws` provider (hashicorp/aws ~> 5.0)
  - `provider "aws"` block with `region` variable
  - `aws_s3_bucket` with versioning enabled and server-side encryption (AES256)
  - `aws_s3_bucket_versioning` resource
  - `aws_s3_bucket_server_side_encryption_configuration` resource
  - `aws_s3_bucket_public_access_block` to block all public access
  - `aws_dynamodb_table` with hash key `LockID` (string), billing mode PAY_PER_REQUEST
  - Tag all resources with `Project=emerald-grove`, `ManagedBy=opentofu`
- [x] 1.4 Create `infra/bootstrap/variables.tf` with variables: `region` (default `us-east-1`), `state_bucket_name`, `lock_table_name`.
- [x] 1.5 Create `infra/bootstrap/outputs.tf` exposing `state_bucket_name`, `lock_table_name`, and `region`.
- [x] 1.6 Create `infra/README.md` documenting: prerequisites (AWS CLI configured, Mise installed), bootstrap steps (`tofu -chdir=infra/bootstrap init`, `plan`, `apply`), how to run `tofu plan` for each environment, directory structure overview.
- [x] 1.7 Verify: run `tofu -chdir=infra/bootstrap init` and `tofu -chdir=infra/bootstrap plan -var='state_bucket_name=emerald-grove-tfstate' -var='lock_table_name=emerald-grove-tflock'`. Both must succeed.
- [x] 1.8 Save proof artifact output to `docs/specs/13-spec-opentofu-foundation/13-proofs/13-task-01-proofs.md`

### [x] 2.0 Networking Module (VPC, Subnets, Security Groups, ALB)

Create `infra/modules/networking/` with VPC, public subnets, internet gateway, security groups (ALB, ECS, RDS), and the Application Load Balancer with HTTP listener and health check target group. Create the root module skeleton (`providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`) that uses the networking module.

#### 2.0 Proof Artifact(s)

- CLI: `tofu -chdir=infra init` succeeds with backend config, demonstrating provider and backend setup works
- CLI: `tofu -chdir=infra plan -var-file=environments/staging.tfvars` shows VPC, subnets, IGW, security groups, and ALB resources, demonstrating the networking module plans correctly

#### 2.0 Tasks

- [x] 2.1 Create `infra/providers.tf` with:
  - `terraform` block requiring `aws ~> 5.0` and `random ~> 3.0` providers, and an S3 backend block (bucket, key, region, dynamodb_table as variables — use partial config, values supplied via `-backend-config` or hardcoded for this exercise)
  - `provider "aws"` with `region = var.region` and default tags (`Project`, `Environment`, `ManagedBy`)
- [x] 2.2 Create `infra/variables.tf` with root-level variables: `region` (default `us-east-1`), `environment` (string), `project` (default `emerald-grove`), `vpc_cidr` (default `10.0.0.0/16`), `app_port` (default `8080`).
- [x] 2.3 Create `infra/modules/networking/variables.tf` with inputs: `environment`, `project`, `vpc_cidr`, `app_port`.
- [x] 2.4 Create `infra/modules/networking/main.tf` with:
  - `aws_vpc` with DNS support and hostnames enabled
  - 2 `aws_subnet` resources in different AZs (use `data.aws_availability_zones.available`), CIDR sliced from VPC CIDR
  - `aws_internet_gateway` attached to VPC
  - `aws_route_table` with default route to IGW, and `aws_route_table_association` for each subnet
  - `aws_security_group` for ALB: inbound HTTP (80) from `0.0.0.0/0`, outbound all
  - `aws_security_group` for ECS: inbound on `var.app_port` from ALB SG only, outbound all
  - `aws_security_group` for RDS: inbound PostgreSQL (5432) from ECS SG only, outbound all
  - `aws_lb` (application) in public subnets with ALB security group
  - `aws_lb_target_group` on port `var.app_port` with health check on `/actuator/health` (target type `ip` for Fargate)
  - `aws_lb_listener` on port 80 forwarding to the target group
- [x] 2.5 Create `infra/modules/networking/outputs.tf` exposing: `vpc_id`, `public_subnet_ids`, `alb_arn`, `alb_dns_name`, `alb_target_group_arn`, `alb_security_group_id`, `ecs_security_group_id`, `rds_security_group_id`.
- [x] 2.6 Create `infra/main.tf` with the networking module block, passing variables from root.
- [x] 2.7 Create `infra/outputs.tf` exposing `alb_dns_name` from the networking module.
- [x] 2.8 Create `infra/environments/staging.tfvars` with `environment = "staging"` (minimal for now, more values added in later tasks).
- [x] 2.9 Create `infra/environments/prod.tfvars` with `environment = "prod"`.
- [x] 2.10 Verify: run `tofu -chdir=infra init -backend=false` (skip backend since S3 doesn't exist) and `tofu -chdir=infra plan -var-file=environments/staging.tfvars`. Plan must succeed showing VPC, subnets, ALB, and security group resources.
- [x] 2.11 Save proof artifact output to `docs/specs/13-spec-opentofu-foundation/13-proofs/13-task-02-proofs.md`

### [x] 3.0 ECR Module (Container Registry)

Create `infra/modules/ecr/` with the ECR repository, image scanning, immutable tags, and lifecycle policy. Wire into the root module.

#### 3.0 Proof Artifact(s)

- CLI: `tofu -chdir=infra plan -var-file=environments/staging.tfvars` shows ECR repository with scanning and lifecycle policy, demonstrating the ECR module plans correctly

#### 3.0 Tasks

- [x] 3.1 Create `infra/modules/ecr/variables.tf` with inputs: `environment`, `project`.
- [x] 3.2 Create `infra/modules/ecr/main.tf` with:
  - `aws_ecr_repository` with name `${var.project}-${var.environment}`, image tag mutability `IMMUTABLE`, image scanning on push enabled
  - `aws_ecr_lifecycle_policy` keeping the last 10 tagged images (expire untagged after 1 day)
- [x] 3.3 Create `infra/modules/ecr/outputs.tf` exposing: `repository_url`, `repository_arn`.
- [x] 3.4 Add the ECR module to `infra/main.tf`. Add `ecr_repository_url` to `infra/outputs.tf`.
- [x] 3.5 Verify: `tofu -chdir=infra plan -var-file=environments/staging.tfvars` shows ECR resources.
- [x] 3.6 Save proof artifact output to `docs/specs/13-spec-opentofu-foundation/13-proofs/13-task-03-proofs.md`

### [x] 4.0 RDS Module (PostgreSQL Database)

Create `infra/modules/rds/` with the RDS PostgreSQL instance, random password generation, Secrets Manager secret for the database password, and DB subnet group. Wire into the root module.

#### 4.0 Proof Artifact(s)

- CLI: `tofu -chdir=infra plan -var-file=environments/staging.tfvars` shows RDS instance, random password, Secrets Manager secret, and DB subnet group, demonstrating the RDS module plans correctly

#### 4.0 Tasks

- [x] 4.1 Create `infra/modules/rds/variables.tf` with inputs: `environment`, `project`, `subnet_ids` (list of subnet IDs), `security_group_id`, `instance_class` (default `db.t4g.micro`), `db_name` (default `petclinic`), `db_username` (default `petclinic`), `allocated_storage` (default `20`).
- [x] 4.2 Create `infra/modules/rds/main.tf` with:
  - `random_password` resource (length 32, special characters enabled but limited to safe set)
  - `aws_db_subnet_group` using the provided subnet IDs
  - `aws_db_instance` with: engine `postgres`, engine version `16`, instance class from variable, allocated storage, db name, username, password from `random_password`, db subnet group, security group, `publicly_accessible = false`, `skip_final_snapshot = true`, `deletion_protection = false`, storage type `gp3`
  - `aws_secretsmanager_secret` for the database password (name: `${var.project}/${var.environment}/db-password`)
  - `aws_secretsmanager_secret_version` storing the generated password
  - `aws_secretsmanager_secret` for the Anthropic API key (name: `${var.project}/${var.environment}/anthropic-api-key`) — placeholder, real value set out-of-band
  - `aws_secretsmanager_secret_version` with placeholder value `CHANGE_ME`
- [x] 4.3 Create `infra/modules/rds/outputs.tf` exposing: `db_endpoint`, `db_name`, `db_username`, `db_password_secret_arn`, `anthropic_api_key_secret_arn`.
- [x] 4.4 Add the RDS module to `infra/main.tf`, passing `subnet_ids` and `security_group_id` from the networking module. Add `rds_endpoint` to `infra/outputs.tf`.
- [x] 4.5 Verify: `tofu -chdir=infra plan -var-file=environments/staging.tfvars` shows RDS instance, secrets, and subnet group.
- [x] 4.6 Save proof artifact output to `docs/specs/13-spec-opentofu-foundation/13-proofs/13-task-04-proofs.md`

### [x] 5.0 ECS Module (Fargate Service) and Environment Parameterization

Create `infra/modules/ecs/` with ECS cluster, task definition (secrets from Secrets Manager, CloudWatch Logs), Fargate service with ALB attachment, and IAM roles. Create `staging.tfvars` and `prod.tfvars`. Verify both environments plan successfully.

#### 5.0 Proof Artifact(s)

- CLI: `tofu -chdir=infra plan -var-file=environments/staging.tfvars` shows full infrastructure (all modules) with staging values, demonstrating end-to-end plan works
- CLI: `tofu -chdir=infra plan -var-file=environments/prod.tfvars` shows full infrastructure with prod values, demonstrating environment parameterization works
- Diff: `staging.tfvars` and `prod.tfvars` show different environment-specific values

#### 5.0 Tasks

- [x] 5.1 Create `infra/modules/ecs/variables.tf` with inputs: `environment`, `project`, `container_image` (ECR URL), `container_port` (default `8080`), `cpu` (default `1024`), `memory` (default `2048`), `desired_count` (default `1`), `subnet_ids`, `security_group_id`, `target_group_arn`, `db_endpoint`, `db_name`, `db_username`, `db_password_secret_arn`, `anthropic_api_key_secret_arn`.
- [x] 5.2 Create `infra/modules/ecs/main.tf` with:
  - `aws_ecs_cluster` with Fargate capacity provider
  - `aws_cloudwatch_log_group` for container logs (name: `/ecs/${var.project}-${var.environment}`, retention 14 days)
  - `aws_iam_role` for task execution (trust policy for `ecs-tasks.amazonaws.com`) with attached policies:
    - `arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy` (ECR pull + CloudWatch Logs)
    - Inline policy for Secrets Manager read (`secretsmanager:GetSecretValue` on the db password and API key ARNs)
  - `aws_iam_role` for the task itself (minimal, trust `ecs-tasks.amazonaws.com`)
  - `aws_ecs_task_definition` with: family `${var.project}-${var.environment}`, requires compatibilities `FARGATE`, network mode `awsvpc`, CPU/memory from variables, execution role ARN, task role ARN, container definition JSON with:
    - Image: `var.container_image`
    - Port mapping: `var.container_port`
    - Environment: `SPRING_PROFILES_ACTIVE=postgres`
    - Secrets (from Secrets Manager): `POSTGRES_PASS`, `ANTHROPIC_API_KEY`
    - Environment (plain): `POSTGRES_URL` constructed as `jdbc:postgresql://${var.db_endpoint}/${var.db_name}`, `POSTGRES_USER` = `var.db_username`
    - Log configuration: awslogs driver pointing to the CloudWatch log group
  - `aws_ecs_service` with: cluster ARN, task definition ARN, desired count, Fargate launch type, network configuration (subnets, security group, `assign_public_ip = true`), load balancer block (target group ARN, container name, container port), health check grace period 60s
- [x] 5.3 Create `infra/modules/ecs/outputs.tf` exposing: `cluster_name`, `service_name`, `task_definition_arn`.
- [x] 5.4 Add the ECS module to `infra/main.tf`, passing outputs from networking, ecr, and rds modules. Add `ecs_cluster_name`, `ecs_service_name` to `infra/outputs.tf`.
- [x] 5.5 Update `infra/environments/staging.tfvars` with all environment-specific values: `environment = "staging"`.
- [x] 5.6 Update `infra/environments/prod.tfvars` with: `environment = "prod"`.
- [x] 5.7 Verify both environments plan successfully:
  - `tofu -chdir=infra plan -var-file=environments/staging.tfvars` — full plan with all resources
  - `tofu -chdir=infra plan -var-file=environments/prod.tfvars` — full plan with prod values
  - Both must succeed with no errors
- [x] 5.8 Save proof artifact output to `docs/specs/13-spec-opentofu-foundation/13-proofs/13-task-05-proofs.md`
