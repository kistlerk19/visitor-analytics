#!/bin/bash

set -e

# Deactivate DR Killswitch - Return to Normal
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔄 DEACTIVATING DR KILLSWITCH"
echo "This will:"
echo "  - Scale PRIMARY region to 2 tasks"
echo "  - Scale DR region to 0 tasks"
echo ""

cd "$PROJECT_DIR"

# Update terraform.tfvars
echo "🔄 Deactivating DR killswitch..."
sed -i 's/dr_killswitch.*=.*true/dr_killswitch = false/' terraform.tfvars

# Apply changes
echo "🚀 Applying normal configuration..."
terraform plan -out=tfplan-normal
terraform apply -auto-approve tfplan-normal

echo ""
echo "✅ DR KILLSWITCH DEACTIVATED"
echo "Primary region: SCALED TO 2"
echo "DR region: SCALED TO 0"
echo ""
echo "Primary Application URL: http://$(terraform output -raw primary_alb_dns)"