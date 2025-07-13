#!/bin/bash

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Enabling Disaster Recovery ==="

cd "$PROJECT_DIR"

# Update terraform.tfvars to enable DR
echo "Updating terraform.tfvars to enable DR..."
sed -i 's/enable_dr.*=.*false/enable_dr = true/' terraform.tfvars

# Plan and apply changes
echo "Planning DR infrastructure..."
terraform plan -out=tfplan-dr

echo "Applying DR infrastructure..."
terraform apply tfplan-dr

# Build and push images to DR region
echo "Building and pushing images to DR region..."
../scripts/build-push.sh --enable-dr

echo "=== DR Setup Complete ==="
echo "DR ALB DNS: $(terraform output -raw dr_alb_dns)"
echo "DR DB Endpoint: $(terraform output -raw dr_db_endpoint)"
echo ""
echo "DR infrastructure is now ready (scaled to 0)"
echo "Use ./scripts/failover.sh to activate DR in case of disaster"