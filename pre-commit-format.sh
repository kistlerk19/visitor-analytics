#!/bin/bash

set -e

echo "🔧 Pre-commit Terraform formatting..."

cd disaster-recovery

# Format all Terraform files
terraform fmt

# Check if any files were changed
if ! git diff --quiet --exit-code; then
    echo "✅ Terraform files formatted"
    echo "📝 Please commit the formatted files"
    git add *.tf modules/**/*.tf
else
    echo "✅ All Terraform files already properly formatted"
fi

echo "🎉 Pre-commit formatting complete"