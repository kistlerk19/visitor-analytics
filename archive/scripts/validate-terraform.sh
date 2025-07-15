#!/bin/bash

set -e

echo "🔍 Validating Terraform Configuration..."

cd disaster-recovery

# Format check
echo "📝 Checking Terraform formatting..."
terraform fmt -check -recursive

# Initialize without backend
echo "🚀 Initializing Terraform..."
terraform init -backend=false

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

echo "🎉 Terraform validation completed successfully!"
echo ""
echo "✅ All checks passed:"
echo "   - Formatting is correct"
echo "   - Syntax is valid"
echo "   - Provider configurations are correct"
echo "   - Module references are valid"