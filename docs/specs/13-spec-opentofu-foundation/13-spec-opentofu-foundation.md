# 13-spec-opentofu-foundation

## Introduction/Overview

The Emerald Grove Veterinary Clinic application has a production Containerfile (Spec 11) and a Dagger CI pipeline (Spec 12) but no cloud infrastructure to deploy to. This spec creates the AWS foundation using OpenTofu: a VPC, ECR repository, ECS Fargate service, RDS PostgreSQL database, ALB, IAM roles, and security groups for staging and production environments. A separate bootstrap config provisions the S3 + DynamoDB state backend. All infrastructure is code — no AWS console changes (Constitution Article 12).

## Goals

- Create an `infra/` directory with OpenTofu modules for all AWS resources needed to run the application
- Support two environments (staging, prod) via tfvars files with a single root module
- Bootstrap an S3 + DynamoDB remote state backend
- Integrate with the existing Containerfile (Spec 11) and Dagger pipeline (Spec 12) so that images built by CI can be deployed to ECS Fargate
- Manage application secrets (database password, Anthropic API key) via AWS Secrets Manager

## User Stories

- **As a DevOps engineer**, I want to run `tofu plan -var-file=environments/staging.tfvars` so that I can preview infrastructure changes before applying them.
- **As a developer**, I want the application deployed to ECS Fargate behind an ALB so that I can access it via a URL without managing servers.
- **As a security engineer**, I want database credentials and API keys stored in AWS Secrets Manager so that secrets are never in code or environment variable plaintext.
- **As a team lead**, I want staging and production environments parameterized from the same module so that environments don't drift apart.

## Demoable Units of Work

### Unit 1: State Backend Bootstrap

**Purpose:** Create the S3 bucket and DynamoDB table needed for OpenTofu remote state locking, so all subsequent infrastructure changes are safely stored and locked.

**Functional Requirements:**

- An `infra/bootstrap/` directory shall contain an OpenTofu config that creates:
  - An S3 bucket (versioning enabled, server-side encryption) for state storage
  - A DynamoDB table (hash key: `LockID`) for state locking
- The bootstrap config shall use local state (since the remote backend doesn't exist yet)
- The bootstrap config shall use variables for the bucket name and table name so they can be customized
- A `README.md` in `infra/` shall document the bootstrap process

**Proof Artifacts:**

- CLI: `tofu -chdir=infra/bootstrap init` succeeds, demonstrating the config is valid
- CLI: `tofu -chdir=infra/bootstrap plan` shows the S3 bucket and DynamoDB table will be created

### Unit 2: Networking and Load Balancer

**Purpose:** Create the VPC, subnets, security groups, and ALB that form the network foundation for the application.

**Functional Requirements:**

- An `infra/modules/networking/` module shall create:
  - A VPC with a configurable CIDR block (default `10.0.0.0/16`)
  - 2 public subnets across 2 availability zones (for ALB high availability)
  - An internet gateway attached to the VPC
  - A route table with a default route to the internet gateway
  - A security group for the ALB allowing inbound HTTP (port 80) from anywhere
  - A security group for ECS tasks allowing inbound traffic only from the ALB security group on port 8080
  - A security group for RDS allowing inbound PostgreSQL (port 5432) only from the ECS security group
- An `infra/modules/networking/` module shall create an ALB:
  - Application Load Balancer in the public subnets
  - HTTP listener on port 80 forwarding to a target group on port 8080
  - Target group with health check on `/actuator/health`
- All resources shall be tagged with `Environment`, `Project`, and `ManagedBy=opentofu`

**Proof Artifacts:**

- CLI: `tofu -chdir=infra plan -var-file=environments/staging.tfvars` shows VPC, subnets, ALB, and security groups will be created

### Unit 3: ECR, ECS Fargate, and RDS PostgreSQL

**Purpose:** Create the compute and data layers — ECR for container images, ECS Fargate for running the application, and RDS for the PostgreSQL database.

**Functional Requirements:**

- An `infra/modules/ecr/` module shall create an ECR repository with:
  - Image tag mutability set to immutable
  - Image scanning on push enabled
  - Lifecycle policy to keep the last 10 images
- An `infra/modules/ecs/` module shall create:
  - An ECS cluster with Fargate capacity provider
  - A task definition with: 1 vCPU, 2 GB memory, the application container image from ECR, port mapping 8080, environment variables sourced from Secrets Manager (`POSTGRES_URL`, `POSTGRES_USER`, `POSTGRES_PASS`, `ANTHROPIC_API_KEY`, `SPRING_PROFILES_ACTIVE=postgres`), CloudWatch Logs log driver
  - An ECS service with: desired count of 1, Fargate launch type, public subnet placement with public IP (assign_public_ip=true), ALB target group attachment, health check grace period of 60 seconds
  - A task execution IAM role with permissions to pull from ECR, read Secrets Manager secrets, and write CloudWatch Logs
  - A task IAM role (for the running container) with minimal permissions
- An `infra/modules/rds/` module shall create:
  - An RDS PostgreSQL instance (engine version 16, db.t4g.micro, 20 GB gp3 storage)
  - Single-AZ deployment
  - Database name `petclinic`, master username `petclinic`
  - Master password generated by OpenTofu and stored in Secrets Manager
  - A DB subnet group using the public subnets
  - Skip final snapshot (learning exercise)
  - Deletion protection disabled (learning exercise)
- The root module (`infra/main.tf`) shall compose all modules and wire them together
- `infra/variables.tf` shall define all input variables with descriptions and defaults where appropriate
- `infra/outputs.tf` shall expose: ALB DNS name, ECR repository URL, RDS endpoint, ECS cluster name, ECS service name

**Proof Artifacts:**

- CLI: `tofu -chdir=infra plan -var-file=environments/staging.tfvars` shows all resources (ECR, ECS cluster, task definition, service, RDS) will be created
- CLI: `tofu -chdir=infra plan -var-file=environments/prod.tfvars` shows the same resources with production-specific values

### Unit 4: Environment Parameterization and Secrets

**Purpose:** Create staging and production tfvars files and wire secrets from Secrets Manager into the ECS task definition.

**Functional Requirements:**

- `infra/environments/staging.tfvars` shall define staging-specific values (environment name, instance sizes, desired counts)
- `infra/environments/prod.tfvars` shall define production-specific values
- The ECS task definition shall reference Secrets Manager ARNs for:
  - `POSTGRES_URL` (constructed from RDS endpoint output)
  - `POSTGRES_USER` (from RDS config)
  - `POSTGRES_PASS` (generated password stored in Secrets Manager)
  - `ANTHROPIC_API_KEY` (stored in Secrets Manager, populated manually after first apply)
- An OpenTofu resource shall create Secrets Manager secrets for the Anthropic API key (with placeholder value — the real value is set manually or via CI after initial apply)
- The `SPRING_PROFILES_ACTIVE=postgres` shall be set as a plain environment variable (not a secret)

**Proof Artifacts:**

- Diff: `staging.tfvars` and `prod.tfvars` show different values for environment name, demonstrating parameterization
- CLI: `tofu -chdir=infra plan -var-file=environments/staging.tfvars` and `tofu -chdir=infra plan -var-file=environments/prod.tfvars` both succeed with no errors, demonstrating both environments are valid

## Non-Goals (Out of Scope)

1. **Actual AWS deployment (`tofu apply`)** — AWS is not bootstrapped yet. This spec produces valid, plan-able OpenTofu configs. Actual deployment happens when the user is ready.
2. **CD pipeline integration** — Covered in Spec 14 (CD Pipeline). This spec creates the infrastructure; Spec 14 wires it into Dagger.
3. **Monitoring resources (AMP, AMG, CloudWatch dashboards)** — Covered in Spec 15 (Monitoring & Observability).
4. **HTTPS/TLS certificates** — ALB is HTTP-only for simplicity. HTTPS can be added later with ACM.
5. **Multi-AZ RDS** — Single-AZ for cost savings in a learning exercise.
6. **Auto-scaling** — ECS service runs with desired count of 1. Auto-scaling is a future enhancement.
7. **DNS/Route53** — No custom domain. Access via ALB DNS name.
8. **WAF/Shield** — No web application firewall for a learning exercise.

## Design Considerations

No specific design requirements identified. This is infrastructure work with no UI impact.

## Repository Standards

- Follow conventional commits: `feat(infra): ...` for infrastructure code
- OpenTofu code in `infra/` directory at project root
- Follow Constitution Article 12 (Infrastructure as Code) — all resources defined in code, remote state with locking, parameterized environments, no secrets in IaC files
- Follow HashiCorp/OpenTofu conventions: `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`
- Use meaningful resource names and descriptions
- Tag all resources consistently

## Technical Considerations

- **OpenTofu version**: Use latest stable (1.8+). Mise should manage the version via `.mise.toml`.
- **AWS provider**: Use `hashicorp/aws` provider (compatible with OpenTofu). Pin to a specific version.
- **State backend**: S3 with DynamoDB locking. Backend config in `providers.tf` with partial configuration — bucket/table names passed via `-backend-config` or hardcoded per environment.
- **Module structure**: Each module has `main.tf`, `variables.tf`, `outputs.tf`. Root module composes modules and passes outputs between them.
- **ECS container image**: The task definition references the ECR repository URL + image tag. For initial plan, use a placeholder image tag. The CD pipeline (Spec 14) will update the tag on deploy.
- **RDS password generation**: Use `random_password` resource + `aws_secretsmanager_secret_version` to generate and store the database password.
- **Fargate networking**: With public subnets and `assign_public_ip = true`, Fargate tasks can pull images from ECR and reach the internet directly. No NAT Gateway needed.
- **Mise integration**: Add `opentofu` to `.mise.toml` tools section so developers get the right version automatically.

## Security Considerations

- **No secrets in OpenTofu code**: Database passwords generated via `random_password` and stored in Secrets Manager. Anthropic API key created as an empty secret — real value set out-of-band.
- **No secrets in state files**: While state files contain sensitive data by nature, S3 server-side encryption and bucket versioning protect them. State backend uses OpenTofu's native state encryption if available.
- **IAM least privilege**: Task execution role has only the permissions needed (ECR pull, Secrets Manager read, CloudWatch Logs write). Task role has minimal permissions.
- **Security groups**: Default deny. ALB accepts HTTP from anywhere. ECS only from ALB. RDS only from ECS.
- **RDS not publicly accessible**: Even though it's in a public subnet, `publicly_accessible = false` ensures it has no public IP. Only reachable via security group from ECS tasks.
- **Proof artifacts**: `tofu plan` output may contain resource IDs and ARNs but no secret values. Safe to commit.

## Success Metrics

1. **`tofu plan` succeeds for both environments** — no errors, shows expected resources
2. **Single module, two environments** — staging and prod use the same root module with different tfvars
3. **All resources tagged consistently** — Environment, Project, ManagedBy tags on every resource
4. **Secrets in Secrets Manager** — no plaintext credentials in tfvars, environment variables, or state config
5. **Clean module interfaces** — each module has clear inputs (variables) and outputs

## Open Questions

No open questions at this time. The ECS task definition will reference the ECR repository URL via OpenTofu expression (`"${aws_ecr_repository.app.repository_url}:latest"`), which resolves at plan/apply time. The service won't start successfully until an image is pushed (Spec 14), which is expected.
