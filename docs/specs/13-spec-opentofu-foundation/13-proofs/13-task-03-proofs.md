# Task 3.0 Proof Artifacts: ECR Module

## tofu validate

```bash
$ tofu -chdir=infra validate
Success! The configuration is valid.
```

## ECR module resources

- `aws_ecr_repository.app` — immutable tags, scan on push
- `aws_ecr_lifecycle_policy.app` — expire untagged after 1 day, keep last 10 tagged
