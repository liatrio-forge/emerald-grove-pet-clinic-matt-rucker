# Task 4.0 Proof Artifacts: Teardown Automation

## Dry Run

```bash
$ mise run teardown
DRY RUN — no resources will be destroyed

The following will be destroyed when run with --confirm:
  1. All infrastructure resources (VPC, ALB, ECR, ECS, RDS, IAM roles, ...)
  2. OpenTofu state files in S3 bucket: emerald-grove-tfstate
  3. S3 state bucket: emerald-grove-tfstate
  4. DynamoDB lock table: emerald-grove-tflock

The following will NOT be destroyed:
  - IAM user used for CLI access (manually created)
```

## Full Teardown

The teardown was executed (with manual assist for state recovery after
initial ordering bug). All resources were destroyed.

## Verification After Teardown

```bash
$ aws ec2 describe-vpcs --filters "Name=tag:Project,Values=emerald-grove"
(empty — no VPCs)

$ aws s3 ls | grep emerald-grove-tfstate
(empty — no bucket)

$ aws dynamodb list-tables | grep emerald-grove-tflock
(empty — no table)

$ aws ecs list-clusters | grep emerald-grove-prod
(empty — no clusters)
```

## Issues Encountered and Fixed

1. **Teardown ordering bug**: Original script emptied S3 (state) before
   running `tofu destroy`, leaving infra orphaned with no state. Fixed:
   destroy infra FIRST, then empty S3, then destroy bootstrap.
2. **Versioned S3 bucket**: `aws s3 rm` doesn't delete object versions.
   Fixed: use `s3api list-object-versions` + delete each version.
3. **ECR non-empty**: ECR repo with images can't be deleted. Fixed:
   added `force_delete = true` to ECR OpenTofu resource.
