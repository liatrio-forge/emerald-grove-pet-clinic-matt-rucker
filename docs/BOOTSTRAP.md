# AWS Bootstrap Guide

This guide walks through the one-time setup required to provision the AWS state backend and prepare the account for infrastructure management with OpenTofu.

## Prerequisites

1. **Mise installed and activated** — see [README Quick Start](../README.md#quick-start)
2. **AWS account** with admin access
3. **IAM user created** with programmatic access (Access Key ID + Secret Access Key)
4. **AWS CLI configured** with credentials:

```bash
aws configure
# AWS Access Key ID: <your-key-id>
# AWS Secret Access Key: <your-secret-key>
# Default region: us-east-1
# Default output: json
```

Verify credentials work:

```bash
aws sts get-caller-identity
```

## What Gets Created

The bootstrap process creates two AWS resources that OpenTofu uses to safely store and lock infrastructure state:

| Resource | Name | Purpose |
|---|---|---|
| S3 Bucket | `emerald-grove-tfstate` | Stores OpenTofu state files (versioned, encrypted, private) |
| DynamoDB Table | `emerald-grove-tflock` | Prevents concurrent state modifications (distributed locking) |

These resources are managed separately from the main infrastructure because they must exist before OpenTofu can use remote state.

## Bootstrap Steps

### Step 1: Initialize

```bash
tofu -chdir=infra/bootstrap init
```

This downloads the AWS provider and prepares the bootstrap directory. State for the bootstrap itself is stored locally (in `infra/bootstrap/terraform.tfstate`).

### Step 2: Review the Plan

```bash
tofu -chdir=infra/bootstrap plan \
  -var='state_bucket_name=emerald-grove-tfstate' \
  -var='lock_table_name=emerald-grove-tflock'
```

Verify the plan shows:

- 1 S3 bucket (with versioning + encryption + public access block)
- 1 DynamoDB table (with `LockID` hash key)

### Step 3: Apply

```bash
tofu -chdir=infra/bootstrap apply \
  -var='state_bucket_name=emerald-grove-tfstate' \
  -var='lock_table_name=emerald-grove-tflock'
```

Type `yes` when prompted. This creates the state backend resources.

### Step 4: Verify

```bash
# Confirm S3 bucket exists
aws s3 ls | grep emerald-grove-tfstate

# Confirm DynamoDB table exists
aws dynamodb describe-table --table-name emerald-grove-tflock --query 'Table.TableName'
```

### Step 5: Initialize Main Infrastructure

Now that the state backend exists, initialize the main infrastructure config:

```bash
tofu -chdir=infra init \
  -backend-config=bucket=emerald-grove-tfstate \
  -backend-config=dynamodb_table=emerald-grove-tflock
```

You can now plan and apply the main infrastructure:

```bash
# Plan staging
tofu -chdir=infra plan -var-file=environments/staging.tfvars

# Plan production
tofu -chdir=infra plan -var-file=environments/prod.tfvars
```

## Tear Down

To destroy the state backend (only do this if you've already destroyed all managed infrastructure):

```bash
tofu -chdir=infra/bootstrap destroy \
  -var='state_bucket_name=emerald-grove-tfstate' \
  -var='lock_table_name=emerald-grove-tflock'
```

The S3 bucket must be empty before it can be destroyed. If it contains state files, empty it first:

```bash
aws s3 rm s3://emerald-grove-tfstate --recursive
```

## Troubleshooting

### "No valid credential sources found"

AWS CLI is not configured or credentials are expired. Run `aws sts get-caller-identity` to verify.

### "BucketAlreadyExists"

The S3 bucket name is globally unique. If someone else has this name, change `state_bucket_name` to something unique (e.g., add your account ID suffix).

### "Table already exists"

The bootstrap was already run. If you need to re-run, either import the existing resources or destroy first.

### Bootstrap state file

The bootstrap's own state is stored locally at `infra/bootstrap/terraform.tfstate`. This file is gitignored. If you lose it, you can import the existing resources:

```bash
tofu -chdir=infra/bootstrap import \
  -var='state_bucket_name=emerald-grove-tfstate' \
  -var='lock_table_name=emerald-grove-tflock' \
  aws_s3_bucket.state emerald-grove-tfstate

tofu -chdir=infra/bootstrap import \
  -var='state_bucket_name=emerald-grove-tfstate' \
  -var='lock_table_name=emerald-grove-tflock' \
  aws_dynamodb_table.lock emerald-grove-tflock
```
