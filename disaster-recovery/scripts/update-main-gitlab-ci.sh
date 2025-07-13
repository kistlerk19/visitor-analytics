#!/bin/bash

set -e

# Script to update main GitLab CI to use Terraform
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "=== Updating Main GitLab CI to use Terraform ==="

# Backup original GitLab CI
cp "$PROJECT_ROOT/.gitlab-ci.yml" "$PROJECT_ROOT/.gitlab-ci.yml.backup"

# Copy new GitLab CI
cp "$SCRIPT_DIR/../.gitlab-ci.yml" "$PROJECT_ROOT/.gitlab-ci.yml"

echo "✅ GitLab CI updated to use Terraform"
echo "✅ Original backed up as .gitlab-ci.yml.backup"
echo ""
echo "Next steps:"
echo "1. Commit and push the updated .gitlab-ci.yml"
echo "2. Set GitLab CI variables:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY" 
echo "   - AWS_ACCOUNT_ID"
echo "   - NOTIFICATION_EMAIL"
echo "3. Push to main branch to trigger deployment"