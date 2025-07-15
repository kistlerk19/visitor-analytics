#!/bin/bash

set -e

# DR Killswitch - Emergency DR Activation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚨 ACTIVATING DR KILLSWITCH 🚨"
echo "This will:"
echo "  - Scale PRIMARY region to 0 tasks"
echo "  - Scale DR region to 2 tasks"
echo ""

read -p "Are you sure? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "DR activation cancelled."
    exit 0
fi

cd "$PROJECT_DIR"

# Update terraform.tfvars
echo "🔄 Activating DR killswitch..."
sed -i 's/dr_killswitch.*=.*false/dr_killswitch = true/' terraform.tfvars 2>/dev/null || echo 'dr_killswitch = true' >> terraform.tfvars

# Apply changes
echo "🚀 Applying DR activation..."
terraform plan -out=tfplan-killswitch
terraform apply -auto-approve tfplan-killswitch

echo ""
echo "🎯 DR KILLSWITCH ACTIVATED"
echo "Primary region: SCALED TO 0"
echo "DR region: SCALED TO 2"
echo ""
echo "DR Application URL: http://$(terraform output -raw dr_alb_dns)"
echo ""
echo "To deactivate: ./scripts/deactivate-dr.sh"