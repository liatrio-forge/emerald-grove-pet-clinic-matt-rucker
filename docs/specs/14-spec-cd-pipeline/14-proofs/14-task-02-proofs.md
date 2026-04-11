# Task 2.0 Proof Artifacts: Dagger Deploy Functions and First Deployment

## mise run deploy

```text
Image tag: [REDACTED].dkr.ecr.us-east-1.amazonaws.com/emerald-grove-prod:cad2029
Pushed: [REDACTED].dkr.ecr.us-east-1.amazonaws.com/emerald-grove-prod:cad2029@sha256:7b47d4a...
Current task definition: arn:aws:ecs:us-east-1:[REDACTED]:task-definition/emerald-grove-prod:1
New task definition: arn:aws:ecs:us-east-1:[REDACTED]:task-definition/emerald-grove-prod:2
emerald-grove-prod-service
ECS deployment triggered
```

## Health check (live application)

```bash
$ curl http://emerald-grove-prod-alb-826753494.us-east-1.elb.amazonaws.com/actuator/health
{"groups":["liveness","readiness"],"status":"UP"}
```

## Homepage

```bash
$ curl -s -o /dev/null -w '%{http_code}' http://emerald-grove-prod-alb-826753494.us-east-1.elb.amazonaws.com/
200
```

## Owners page

```bash
$ curl -s -o /dev/null -w '%{http_code}' 'http://emerald-grove-prod-alb-826753494.us-east-1.elb.amazonaws.com/owners?lastName='
200
```

## Application logs (from CloudWatch)

```text
HikariPool-1 - Start completed.
Database JDBC URL [jdbc:postgresql://emerald-grove-prod-db.[REDACTED].rds.amazonaws.com:5432/petclinic]
Initialized JPA EntityManagerFactory for persistence unit 'default'
```

App connected to RDS PostgreSQL, initialized JPA, and is serving requests.

## Issues encountered and resolved

- Initial task definition used `:latest` placeholder — ECS couldn't pull (no such tag)
- Fixed: Deploy function now registers a new task definition revision with the
  actual git SHA tag, then updates the ECS service to use the new revision
