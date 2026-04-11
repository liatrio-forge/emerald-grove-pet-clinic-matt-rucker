# Task 2.0 Proof Artifacts: Networking Module

## tofu init (root module)

```bash
$ tofu -chdir=infra init
Initializing modules...
- networking in modules/networking
Initializing provider plugins...
- Installing hashicorp/aws v5.100.0...
- Installing hashicorp/random v3.8.1...
OpenTofu has been successfully initialized!
```

## tofu validate

```bash
$ tofu -chdir=infra validate
Success! The configuration is valid.
```

## tofu plan (staging)

```bash
$ tofu -chdir=infra plan -var-file=environments/staging.tfvars
Error: No valid credential sources found
```

Plan correctly requires AWS credentials to evaluate data sources
(availability zones). The config is syntactically valid (confirmed by
`tofu validate`). Full plan execution requires AWS credentials.

## Resources defined in networking module

The networking module (`infra/modules/networking/main.tf`) defines:

- `aws_vpc.main` — VPC with DNS support
- `aws_subnet.public[0]`, `aws_subnet.public[1]` — 2 public subnets in different AZs
- `aws_internet_gateway.main` — IGW attached to VPC
- `aws_route_table.public` — default route to IGW
- `aws_route_table_association.public[0]`, `[1]` — subnet associations
- `aws_security_group.alb` — HTTP from anywhere, egress all
- `aws_security_group.ecs` — app port from ALB SG only, egress all
- `aws_security_group.rds` — PostgreSQL from ECS SG only, egress all
- `aws_lb.main` — application load balancer in public subnets
- `aws_lb_target_group.app` — port 8080, health check `/actuator/health`
- `aws_lb_listener.http` — port 80 forwarding to target group
