# 13 Questions Round 1 - OpenTofu Foundation

Please answer each question below (select one or more options, or add your own notes). Feel free to add additional context under any question.

## 1. AWS Region

Which AWS region should the infrastructure be deployed to?

- [x] (A) us-east-1 (N. Virginia) — cheapest, most services available

## 2. State Backend Bootstrap

The S3 bucket + DynamoDB table for OpenTofu remote state need to exist before we can use them. How should we handle bootstrap?

- [x] (A) Separate bootstrap script (`infra/bootstrap/`) that creates the S3 bucket and DynamoDB table using OpenTofu with local state — run once manually

## 3. RDS Instance Size

What size should the RDS PostgreSQL instances be?

- [x] (A) db.t4g.micro (2 vCPU, 1 GB RAM, free tier eligible) — cheapest, fine for demo/learning

## 4. ECS Fargate Task Size

What CPU/memory for the Fargate tasks?

- [x] (C) 1 vCPU / 2 GB — comfortable for Spring Boot with Spring AI

## 5. Networking: Public vs Private Subnets

How should the VPC be structured?

- [x] (A) Public subnets only — ALB and Fargate tasks in public subnets. Simpler, cheaper (no NAT Gateway). RDS in public subnet with security group restrictions.

Note: Simplest option for a learning exercise. Security groups provide sufficient isolation. Upgrading to private subnets later is a straightforward refactor.

## 6. RDS Multi-AZ

Should RDS be deployed across multiple availability zones?

- [x] (A) Single-AZ for both environments — cheapest, fine for learning

## 7. ALB Configuration

Should the ALB use HTTPS?

- [x] (A) HTTP only (port 80) — no certificate needed, simplest

## 8. Secrets Management

How should application secrets (ANTHROPIC_API_KEY, database password) be managed?

- [x] (A) AWS Secrets Manager — fully managed, automatic rotation support, ~$0.40/secret/month

## 9. OpenTofu Directory Structure

Where should the IaC code live in the repo?

- [x] (A) `infra/` at project root with `modules/`, `environments/staging.tfvars`, `environments/prod.tfvars`

Note: No Terragrunt — plain OpenTofu with tfvars per environment. KISS for 2 environments.

## 10. Proof Artifacts

What would best demonstrate this spec is working?

- [x] (B) `tofu plan` only (no actual AWS resources created) — validate the config is correct without spending money. AWS is not bootstrapped yet.
