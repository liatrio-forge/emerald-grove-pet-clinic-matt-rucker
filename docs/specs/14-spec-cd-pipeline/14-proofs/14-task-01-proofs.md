# Task 1.0 Proof Artifacts: Environment Consolidation and Infrastructure Apply

## tofu apply

```text
Apply complete! Resources: 17 added, 0 changed, 0 destroyed.
(4 IAM identity resources were created in a prior partial apply)
Total: 21 resources created
```

## tofu output

```text
alb_dns_name = "emerald-grove-prod-alb-826753494.us-east-1.elb.amazonaws.com"
ci_role_arn = "arn:aws:iam::[REDACTED]:role/emerald-grove-prod-ci"
ecr_repository_url = "[REDACTED].dkr.ecr.us-east-1.amazonaws.com/emerald-grove-prod"
ecs_cluster_name = "emerald-grove-prod-cluster"
ecs_service_name = "emerald-grove-prod-service"
rds_endpoint = "emerald-grove-prod-db.[REDACTED].us-east-1.rds.amazonaws.com:5432"
tofu_role_arn = "arn:aws:iam::[REDACTED]:role/emerald-grove-prod-tofu"
```

## Environment consolidation

- staging.tfvars: DELETED
- prod.tfvars: sole environment
- mise tofu:plan updated to use prod.tfvars

## Issues encountered and resolved

- OIDC provider already existed in shared account — switched to data source
- VPC limit (5) exceeded — requested increase to 10, waited for propagation
