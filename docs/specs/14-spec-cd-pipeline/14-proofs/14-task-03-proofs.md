# Task 3.0 Proof Artifacts: GitHub Actions CD Workflow

## ci.yml content

The workflow uses OIDC authentication, deploy-on-main gating, and Dagger
for all deploy logic. No AWS CLI commands in the YAML.

Key elements:

- `permissions: id-token: write, contents: read` for OIDC
- `aws-actions/configure-aws-credentials@v4` with `role-to-assume`
- Deploy step gated on `github.ref == 'refs/heads/main' && github.event_name == 'push'`
- Deploy calls `dagger -m dagger call deploy` with registry, cluster, service params
- Secrets passed via `env:AWS_ACCESS_KEY_ID` (set by configure-aws-credentials)

## No AWS CLI commands in workflow

```bash
$ grep -E "aws ecr|aws ecs|docker|ecr get-login" .github/workflows/ci.yml
(no output — zero AWS CLI commands)
```

All deploy logic lives in `dagger/main.go`.
