# Migration Guide: ECS CLI → Terraform

This guide helps you migrate from the existing ECS CLI deployment to the new Terraform-based infrastructure.

## 🔄 Migration Steps

### 1. Backup Current Infrastructure
```bash
# Export current ECS service configuration
aws ecs describe-services --cluster lamp-visitor-analytics --services lamp-visitor-analytics > current-service.json

# Export current task definition
aws ecs describe-task-definition --task-definition lamp-visitor-analytics > current-task-def.json
```

### 2. Update GitLab CI
```bash
cd disaster-recovery
./scripts/update-main-gitlab-ci.sh
```

### 3. Deploy Terraform Infrastructure
```bash
# Option A: Manual deployment
./scripts/deploy.sh

# Option B: GitLab CI deployment
git add .
git commit -m "Add Terraform infrastructure"
git push origin main
```

### 4. Verify Migration
```bash
# Check new infrastructure
terraform output primary_alb_dns
terraform output primary_db_endpoint

# Test application
curl http://$(terraform output -raw primary_alb_dns)/health.php
```

## 🔍 Key Differences

### ECS CLI vs Terraform

| Component | ECS CLI | Terraform |
|-----------|---------|-----------|
| **Database** | MySQL container | RDS MySQL |
| **Credentials** | Environment vars | Secrets Manager |
| **Infrastructure** | Shell scripts | Terraform modules |
| **State Management** | None | Terraform state |
| **DR Support** | Manual | Automated |

### Task Definition Changes

**Before (ECS CLI):**
```json
{
  "environment": [
    {"name": "DB_HOST", "value": "127.0.0.1"},
    {"name": "DB_PASSWORD", "value": "rootpassword"}
  ]
}
```

**After (Terraform):**
```json
{
  "secrets": [
    {"name": "DB_CREDENTIALS", "valueFrom": "arn:aws:secretsmanager:..."}
  ],
  "environment": [
    {"name": "DB_HOST", "value": "rds-endpoint"}
  ]
}
```

## 🚨 Migration Checklist

### Pre-Migration
- [ ] Backup current ECS service configuration
- [ ] Export application data if needed
- [ ] Test Terraform deployment in separate environment
- [ ] Update GitLab CI variables

### During Migration
- [ ] Deploy Terraform infrastructure
- [ ] Migrate data from MySQL container to RDS
- [ ] Update DNS records if needed
- [ ] Test application functionality

### Post-Migration
- [ ] Verify all endpoints work
- [ ] Check CloudWatch logs
- [ ] Test auto-scaling
- [ ] Enable DR if needed
- [ ] Clean up old resources

## 🔧 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   ```bash
   # Check RDS security groups
   aws ec2 describe-security-groups --group-ids sg-xxxxx
   
   # Check secrets manager
   aws secretsmanager get-secret-value --secret-id lamp-visitor-analytics-db-credentials
   ```

2. **ECS Tasks Not Starting**
   ```bash
   # Check task definition
   aws ecs describe-task-definition --task-definition lamp-visitor-analytics
   
   # Check service events
   aws ecs describe-services --cluster lamp-visitor-analytics --services lamp-visitor-analytics
   ```

3. **ALB Health Checks Failing**
   ```bash
   # Check target group health
   aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...
   ```

## 🔄 Rollback Plan

If migration fails, rollback using:

```bash
# Restore original GitLab CI
cp .gitlab-ci.yml.backup .gitlab-ci.yml

# Scale down Terraform resources
terraform destroy -target=module.primary_ecs

# Restore ECS CLI deployment
./ecs-deploy.sh application
```

## 📊 Cost Comparison

### Before (ECS CLI)
- ECS Fargate: ~$15/month
- EFS: ~$3/month
- ALB: ~$18/month
- **Total**: ~$36/month

### After (Terraform)
- ECS Fargate: ~$15/month
- RDS t3.micro: ~$15/month
- Secrets Manager: ~$0.40/month
- ALB: ~$18/month
- **Total**: ~$48/month

**Additional DR Cost**: ~$65/month when enabled

## 🎯 Benefits After Migration

- ✅ **Managed Database**: RDS instead of container MySQL
- ✅ **Secure Credentials**: AWS Secrets Manager
- ✅ **Infrastructure as Code**: Version-controlled Terraform
- ✅ **Disaster Recovery**: Cross-region replication ready
- ✅ **Better Monitoring**: CloudWatch integration
- ✅ **Scalable Architecture**: Modular Terraform design