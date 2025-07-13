#!/bin/bash

set -e

echo "🧹 Complete Infrastructure Cleanup"
echo "⚠️  This will DELETE ALL resources created by this project"
read -p "Are you sure? Type 'DELETE' to continue: " confirm

if [ "$confirm" != "DELETE" ]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

cd disaster-recovery

# Destroy Terraform resources
terraform destroy -auto-approve || true

# Manual cleanup of any remaining resources
aws ecr delete-repository --repository-name lamp-apache --force 2>/dev/null || true
aws logs delete-log-group --log-group-name /ecs/lamp-visitor-analytics 2>/dev/null || true

echo "✅ Cleanup complete"