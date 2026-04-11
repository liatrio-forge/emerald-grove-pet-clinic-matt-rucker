# Task 5.0 Proof Artifacts: ECS Module and Environment Parameterization

## tofu validate (all modules)

```bash
$ tofu -chdir=infra validate
Success! The configuration is valid.
```

Validates the complete config: networking + ecr + rds + ecs modules composed
in the root module.

## ECS module resources

- `aws_ecs_cluster.main` — Fargate with container insights
- `aws_cloudwatch_log_group.app` — `/ecs/{project}-{env}`, 14 day retention
- `aws_iam_role.task_execution` — ECR pull, CloudWatch Logs, Secrets Manager read
- `aws_iam_role.task` — minimal task role
- `aws_ecs_task_definition.app` — 1 vCPU, 2 GB, Fargate, awsvpc
  - Environment: `SPRING_PROFILES_ACTIVE=postgres`, `POSTGRES_URL`, `POSTGRES_USER`
  - Secrets: `POSTGRES_PASS` (from Secrets Manager), `ANTHROPIC_API_KEY` (from Secrets Manager)
  - Logs: awslogs driver to CloudWatch
- `aws_ecs_service.app` — desired count 1, public IP, ALB attachment, 60s health grace

## Environment parameterization

staging.tfvars:

```hcl
environment = "staging"
```

prod.tfvars:

```hcl
environment = "prod"
```

Both use the same root module. Resource names are prefixed with
`{project}-{environment}` for isolation.

## tofu plan (staging and prod)

Both `tofu plan -var-file=environments/staging.tfvars` and
`tofu plan -var-file=environments/prod.tfvars` require AWS credentials
to evaluate data sources. The config is validated as syntactically correct
via `tofu validate`. Full plan execution will work once AWS is bootstrapped.
