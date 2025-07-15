#!/bin/bash

set -e

echo "=== GitLab to GitHub Actions Migration Script ==="

# Check if we're in the right directory
if [ ! -f ".gitlab-ci.yml" ]; then
    echo "❌ Error: .gitlab-ci.yml not found. Are you in the project root?"
    exit 1
fi

echo "✅ Found GitLab CI configuration"

# Check if GitHub Actions workflow already exists
if [ -f ".github/workflows/deploy.yml" ]; then
    echo "✅ GitHub Actions workflow already exists"
else
    echo "❌ GitHub Actions workflow not found"
    echo "Please ensure .github/workflows/deploy.yml exists"
    exit 1
fi

echo ""
echo "🔧 Migration Checklist:"
echo ""
echo "1. Repository Setup:"
echo "   - Fork this repository to GitHub ✓"
echo "   - Clone your GitHub fork locally"
echo ""
echo "2. Configure GitHub Secrets (Settings > Secrets and variables > Actions):"
echo "   Repository Secrets:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY" 
echo "   - AWS_ACCOUNT_ID"
echo "   - NOTIFICATION_EMAIL"
echo ""
echo "   Repository Variables:"
echo "   - ENABLE_DR (set to 'false' or 'true')"
echo ""
echo "3. Test Deployment:"
echo "   - Push to main branch"
echo "   - Check Actions tab for workflow execution"
echo "   - Verify application deployment"
echo ""
echo "4. Optional Cleanup:"
echo "   - Remove .gitlab-ci.yml files (keep for reference if needed)"
echo "   - Update any documentation references"
echo ""

read -p "Do you want to remove GitLab CI files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing GitLab CI files..."
    rm -f .gitlab-ci.yml
    rm -f disaster-recovery/.gitlab-ci.yml
    echo "✅ GitLab CI files removed"
else
    echo "📁 GitLab CI files kept for reference"
fi

echo ""
echo "🎉 Migration preparation complete!"
echo ""
echo "Next steps:"
echo "1. Configure GitHub repository secrets and variables"
echo "2. Push to main branch to trigger first deployment"
echo "3. Monitor workflow in GitHub Actions tab"
echo ""
echo "For detailed instructions, see: GITHUB_ACTIONS_MIGRATION.md"