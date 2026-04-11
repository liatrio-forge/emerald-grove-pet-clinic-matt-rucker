terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # S3 backend is configured in backend.tf (excluded for local-only validation)
  # To plan without AWS: delete or rename backend.tf, run tofu init, tofu plan
  # To plan with AWS: tofu init -backend-config=bucket=emerald-grove-tfstate \
  #                             -backend-config=dynamodb_table=emerald-grove-tflock
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "opentofu"
    }
  }
}
