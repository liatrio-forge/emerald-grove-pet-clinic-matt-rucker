# Task 2.0 Proof Artifacts — ECR Scan Verification + IAM Permissions

## ECR Scan Check in Deploy()

Added ECR scan polling to `Deploy()` in `dagger/main.go` after `image.Publish()`:

- Extracts repo name and image tag from the image reference
- Polls `aws ecr describe-image-scan-findings` in a loop (max 12 retries, 10s sleep)
- On `COMPLETE`: parses `findingSeverityCounts` for CRITICAL and HIGH
- Fails deploy if CRITICAL > 0 or HIGH > 0
- On `FAILED` or timeout: fails deploy

## IAM Permission

```text
$ git diff infra/modules/identity/main.tf
+      "ecr:DescribeImageScanFindings",
```

Added `ecr:DescribeImageScanFindings` to the CI role's `ECRPush` statement, scoped to the ECR repository ARN.

## tofu validate

```text
$ mise exec -- tofu -chdir=infra validate
Success! The configuration is valid.
```
