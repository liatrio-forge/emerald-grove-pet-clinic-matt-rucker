#!/usr/bin/env bash
set -euo pipefail

BUCKET_NAME="emerald-grove-tfstate"
TABLE_NAME="emerald-grove-tflock"
TFVARS="environments/prod.tfvars"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "======================================"
echo "  Emerald Grove — Full AWS Teardown"
echo "======================================"
echo ""

if [[ "${1:-}" != "--confirm" ]]; then
    echo -e "${YELLOW}DRY RUN — no resources will be destroyed${NC}"
    echo ""
    echo "The following will be destroyed when run with --confirm:"
    echo ""
    echo "  1. All infrastructure resources (VPC, ALB, ECR, ECS, RDS, IAM roles,"
    echo "     Secrets Manager, CloudWatch Logs)"
    echo "  2. OpenTofu state files in S3 bucket: ${BUCKET_NAME}"
    echo "  3. S3 state bucket: ${BUCKET_NAME}"
    echo "  4. DynamoDB lock table: ${TABLE_NAME}"
    echo ""
    echo "The following will NOT be destroyed:"
    echo "  - IAM user used for CLI access (manually created)"
    echo "  - ~/.aws/credentials on your machine"
    echo ""
    echo -e "To proceed: ${RED}mise run teardown -- --confirm${NC}"
    echo ""
    exit 0
fi

echo -e "${RED}DESTROYING all AWS resources...${NC}"
echo ""

# Step 1: Destroy infrastructure
echo -e "${YELLOW}Step 1/3: Destroying infrastructure...${NC}"
if tofu -chdir=infra show -json 2>/dev/null | grep -q '"values"'; then
    tofu -chdir=infra destroy -var-file="$TFVARS" -auto-approve
    echo -e "${GREEN}Infrastructure destroyed.${NC}"
else
    echo "No infrastructure state found — skipping."
fi
echo ""

# Step 2: Empty and verify S3 bucket
echo -e "${YELLOW}Step 2/3: Emptying state bucket...${NC}"
if aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
    aws s3 rm "s3://${BUCKET_NAME}" --recursive
    echo -e "${GREEN}State bucket emptied.${NC}"
else
    echo "Bucket ${BUCKET_NAME} not found — skipping."
fi
echo ""

# Step 3: Destroy bootstrap (S3 bucket + DynamoDB table)
echo -e "${YELLOW}Step 3/3: Destroying state backend...${NC}"
if [ -f "infra/bootstrap/terraform.tfstate" ] || tofu -chdir=infra/bootstrap show -json 2>/dev/null | grep -q '"values"'; then
    tofu -chdir=infra/bootstrap destroy \
        -var="state_bucket_name=${BUCKET_NAME}" \
        -var="lock_table_name=${TABLE_NAME}" \
        -auto-approve
    echo -e "${GREEN}State backend destroyed.${NC}"
else
    # Try to import and destroy if state file is missing
    echo "No bootstrap state found. Attempting direct AWS resource deletion..."
    aws s3 rb "s3://${BUCKET_NAME}" --force 2>/dev/null || echo "  Bucket already gone."
    aws dynamodb delete-table --table-name "${TABLE_NAME}" 2>/dev/null || echo "  Table already gone."
    echo -e "${GREEN}State backend cleaned up.${NC}"
fi
echo ""

echo "======================================"
echo -e "${GREEN}  Teardown complete!${NC}"
echo "======================================"
echo ""
echo "Remaining AWS resources:"
echo "  - IAM user (manually created, not managed by OpenTofu)"
echo ""
