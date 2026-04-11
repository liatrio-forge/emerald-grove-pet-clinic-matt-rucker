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

# Step 1: Destroy infrastructure (BEFORE touching the state bucket!)
echo -e "${YELLOW}Step 1/3: Destroying infrastructure...${NC}"
if tofu -chdir=infra init -backend-config=bucket="${BUCKET_NAME}" -backend-config=dynamodb_table="${TABLE_NAME}" -reconfigure 2>/dev/null; then
    if tofu -chdir=infra destroy -var-file="$TFVARS" -auto-approve; then
        echo -e "${GREEN}Infrastructure destroyed.${NC}"
    else
        echo -e "${YELLOW}Some resources may need manual cleanup.${NC}"
    fi
else
    echo "Could not initialize backend — infrastructure may already be destroyed or state bucket is gone."
fi
echo ""

# Step 2: Empty S3 bucket (including all versions for versioned buckets)
echo -e "${YELLOW}Step 2/3: Emptying state bucket...${NC}"
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
    # Delete all object versions (required for versioned buckets)
    aws s3api list-object-versions --bucket "${BUCKET_NAME}" --output json 2>/dev/null | \
        python3 -c "
import json, sys, subprocess
data = json.load(sys.stdin)
for v in data.get('Versions', []):
    subprocess.run(['aws', 's3api', 'delete-object', '--bucket', '${BUCKET_NAME}', '--key', v['Key'], '--version-id', v['VersionId']], capture_output=True)
for m in data.get('DeleteMarkers', []):
    subprocess.run(['aws', 's3api', 'delete-object', '--bucket', '${BUCKET_NAME}', '--key', m['Key'], '--version-id', m['VersionId']], capture_output=True)
print('All versions deleted.')
" 2>/dev/null || aws s3 rm "s3://${BUCKET_NAME}" --recursive
    echo -e "${GREEN}State bucket emptied.${NC}"
else
    echo "Bucket ${BUCKET_NAME} not found — skipping."
fi
echo ""

# Step 3: Destroy bootstrap (S3 bucket + DynamoDB table)
echo -e "${YELLOW}Step 3/3: Destroying state backend...${NC}"
if [ -f "infra/bootstrap/terraform.tfstate" ]; then
    tofu -chdir=infra/bootstrap destroy \
        -var="state_bucket_name=${BUCKET_NAME}" \
        -var="lock_table_name=${TABLE_NAME}" \
        -auto-approve
    echo -e "${GREEN}State backend destroyed.${NC}"
else
    # No local state — destroy resources directly
    echo "No bootstrap state file. Cleaning up directly..."
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
