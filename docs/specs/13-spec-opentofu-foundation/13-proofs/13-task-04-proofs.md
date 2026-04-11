# Task 4.0 Proof Artifacts: RDS Module

## tofu validate

```bash
$ tofu -chdir=infra validate
Success! The configuration is valid.
```

## RDS module resources

- `random_password.db` — 32 char password with safe special chars
- `aws_db_subnet_group.main` — uses public subnets
- `aws_db_instance.main` — PostgreSQL 16, db.t4g.micro, 20GB gp3, single-AZ, not publicly accessible
- `aws_secretsmanager_secret.db_password` + version — auto-generated password
- `aws_secretsmanager_secret.anthropic_api_key` + version — placeholder `CHANGE_ME`
