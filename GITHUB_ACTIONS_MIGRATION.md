# GitHub Actions Migration Guide

This project has been migrated from GitLab CI/CD to GitHub Actions. This guide explains the changes and how to use the new workflow.

## Key Changes

### 1. CI/CD Platform
- **Before**: GitLab CI/CD with `.gitlab-ci.yml`
- **After**: GitHub Actions with `.github/workflows/deploy.yml`

### 2. Environment Variables
- **Before**: GitLab CI Variables
- **After**: GitHub Secrets and Variables

### 3. Workflow Structure
The GitHub Actions workflow maintains the same stages as GitLab CI:
- `validate` - Terraform validation and formatting
- `build` - Docker image build and push to ECR
- `deploy` - Infrastructure deployment with Terraform
- `test` - Application health and API testing
- `enable-dr` - Optional disaster recovery setup

## Setup Instructions

### 1. Repository Setup
1. Fork this repository to your GitHub account
2. Navigate to Settings > Secrets and variables > Actions

### 2. Configure Secrets
Add these **Repository secrets**:
```
AWS_ACCESS_KEY_ID = your-aws-access-key
AWS_SECRET_ACCESS_KEY = your-aws-secret-key
AWS_ACCOUNT_ID = your-12-digit-account-id
NOTIFICATION_EMAIL = admin@yourdomain.com
```

### 3. Configure Variables
Add these **Repository variables**:
```
ENABLE_DR = false  # Set to "true" to enable disaster recovery
```

### 4. Trigger Deployment
- Push to `main` branch to trigger full deployment
- Push to `develop` branch to trigger validation and build only
- Create PR to `main` to trigger validation only

## Workflow Features

### Idempotent Operations
- All operations are designed to be idempotent
- Safe to re-run workflows multiple times
- Automatic cleanup of orphaned resources

### Security
- Uses official AWS Actions for credential management
- Secrets are never exposed in logs
- Least privilege IAM permissions

### Monitoring
- Comprehensive health checks
- Automatic rollback on failure
- CloudWatch integration for logging

## Differences from GitLab CI

### Advantages
- Native AWS integration with official actions
- Better secret management
- More granular workflow control
- Free for public repositories

### Syntax Changes
- `$CI_COMMIT_SHA` → `${{ github.sha }}`
- `$AWS_ACCESS_KEY_ID` → `${{ secrets.AWS_ACCESS_KEY_ID }}`
- `rules:` → `if:` conditions
- `needs:` → `needs:` (same syntax)

## Troubleshooting

### Common Issues
1. **Secrets not found**: Ensure secrets are set at repository level
2. **Workflow not triggering**: Check branch protection rules
3. **AWS permissions**: Verify IAM user has required permissions

### Debug Commands
```bash
# Check workflow runs
gh run list --repo your-username/visitor-analytics

# View workflow logs
gh run view --repo your-username/visitor-analytics

# Check AWS resources
aws ecs describe-services --cluster lamp-visitor-analytics --services lamp-visitor-analytics
```

## Migration Checklist

- [x] Created `.github/workflows/deploy.yml`
- [x] Updated deployment scripts for GitHub Actions
- [x] Modified README.md references
- [x] Created migration documentation
- [ ] Set up GitHub repository secrets
- [ ] Set up GitHub repository variables
- [ ] Test workflow execution
- [ ] Remove old GitLab CI files (optional)

## Next Steps

1. Configure your GitHub repository with the required secrets and variables
2. Push to main branch to trigger the first deployment
3. Monitor the workflow execution in the Actions tab
4. Verify application deployment and health checks
5. Optionally enable disaster recovery by setting `ENABLE_DR = true`