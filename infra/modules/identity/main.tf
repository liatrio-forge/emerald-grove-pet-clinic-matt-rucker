locals {
  name_prefix = "${var.project}-${var.environment}"
}

# --- GitHub Actions OIDC Provider ---
# This allows GitHub Actions to assume IAM roles without long-lived access keys.
# Only needs to be created once per AWS account, but creating per-environment
# with a data source fallback is safe (OpenTofu handles duplicates gracefully).

# Use existing OIDC provider (shared across the AWS account)
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# --- CI Role (GitHub Actions) ---
# Scoped to: ECR push, ECS deploy, Secrets Manager read

data "aws_iam_policy_document" "ci_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only allow this specific repo to assume the role
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "ci" {
  name               = "${local.name_prefix}-ci"
  assume_role_policy = data.aws_iam_policy_document.ci_assume_role.json

  tags = { Name = "${local.name_prefix}-ci" }
}

data "aws_iam_policy_document" "ci_permissions" {
  # ECR: login, push images
  statement {
    sid = "ECRAuth"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECRPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [var.ecr_repository_arn]
  }

  # ECS: update service (force new deployment)
  statement {
    sid = "ECSDeploy"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
    ]
    resources = ["*"]
  }

  # ECS: pass role to task execution and task roles
  statement {
    sid = "PassRole"
    actions = [
      "iam:PassRole",
    ]
    resources = ["arn:aws:iam::*:role/${var.project}-${var.environment}-task*"]
  }
}

resource "aws_iam_role_policy" "ci" {
  name   = "${local.name_prefix}-ci-permissions"
  role   = aws_iam_role.ci.id
  policy = data.aws_iam_policy_document.ci_permissions.json
}

# --- Tofu Role (Infrastructure Management) ---
# Broader permissions for managing all infrastructure resources.
# Used by developers running tofu locally or by CI for infra changes.

data "aws_iam_policy_document" "tofu_assume_role" {
  # Allow the admin user to assume this role locally
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Allow GitHub Actions to assume this role via OIDC
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "tofu" {
  name               = "${local.name_prefix}-tofu"
  assume_role_policy = data.aws_iam_policy_document.tofu_assume_role.json

  tags = { Name = "${local.name_prefix}-tofu" }
}

# Tofu needs broad permissions to manage infra resources.
# Scoped to the services we actually use rather than AdministratorAccess.
data "aws_iam_policy_document" "tofu_permissions" {
  # VPC, networking
  statement {
    sid = "Networking"
    actions = [
      "ec2:*Vpc*", "ec2:*Subnet*", "ec2:*SecurityGroup*",
      "ec2:*InternetGateway*", "ec2:*RouteTable*", "ec2:*Route*",
      "ec2:*NetworkInterface*", "ec2:*Address*",
      "ec2:Describe*", "ec2:CreateTags", "ec2:DeleteTags",
    ]
    resources = ["*"]
  }

  # ECS
  statement {
    sid = "ECS"
    actions = [
      "ecs:*",
    ]
    resources = ["*"]
  }

  # ECR
  statement {
    sid = "ECR"
    actions = [
      "ecr:*",
    ]
    resources = ["*"]
  }

  # RDS
  statement {
    sid = "RDS"
    actions = [
      "rds:*",
    ]
    resources = ["*"]
  }

  # ALB
  statement {
    sid = "ELB"
    actions = [
      "elasticloadbalancing:*",
    ]
    resources = ["*"]
  }

  # Secrets Manager
  statement {
    sid = "SecretsManager"
    actions = [
      "secretsmanager:*",
    ]
    resources = ["*"]
  }

  # IAM (for creating/managing ECS task roles)
  statement {
    sid = "IAM"
    actions = [
      "iam:*Role*", "iam:*Policy*",
      "iam:*InstanceProfile*",
      "iam:*OpenIDConnectProvider*",
    ]
    resources = ["*"]
  }

  # CloudWatch Logs
  statement {
    sid = "CloudWatchLogs"
    actions = [
      "logs:*",
    ]
    resources = ["*"]
  }

  # S3 (state bucket)
  statement {
    sid = "S3State"
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::emerald-grove-tfstate",
      "arn:aws:s3:::emerald-grove-tfstate/*",
    ]
  }

  # DynamoDB (state lock)
  statement {
    sid = "DynamoDBLock"
    actions = [
      "dynamodb:*",
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/emerald-grove-tflock",
    ]
  }
}

resource "aws_iam_role_policy" "tofu" {
  name   = "${local.name_prefix}-tofu-permissions"
  role   = aws_iam_role.tofu.id
  policy = data.aws_iam_policy_document.tofu_permissions.json
}
