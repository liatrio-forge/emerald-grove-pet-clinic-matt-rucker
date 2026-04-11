# S3 backend for remote state storage
# This file is separate so it can be excluded for local-only validation.
# To plan locally without AWS credentials:
#   mv backend.tf backend.tf.bak && tofu init && tofu plan -var-file=environments/staging.tfvars
# To restore: mv backend.tf.bak backend.tf && tofu init -reconfigure

terraform {
  backend "s3" {
    key     = "infra/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    # Supply bucket and dynamodb_table via -backend-config flags:
    #   tofu init -backend-config=bucket=emerald-grove-tfstate \
    #             -backend-config=dynamodb_table=emerald-grove-tflock
  }
}
