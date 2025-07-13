# LAMP Stack Visitor Analytics with Terraform & Disaster Recovery

A cost-optimized containerized LAMP application with automated GitHub Actions CI/CD deployment to AWS using Terraform, featuring disaster recovery capabilities.

## 🚀 Quick Start

### 1. GitHub Setup
1. **Fork** this repository to GitHub
2. **Set Secrets** in Settings > Secrets and variables > Actions > Repository secrets:
   ```
   AWS_ACCESS_KEY_ID = your-aws-access-key
   AWS_SECRET_ACCESS_KEY = your-aws-secret-key
   AWS_ACCOUNT_ID = your-12-digit-account-id
   NOTIFICATION_EMAIL = admin@yourdomain.com
   ```
3. **Set Variables** in Settings > Secrets and variables > Actions > Repository variables:
   ```
   ENABLE_DR = false  # Set to "true" for disaster recovery
   ```

### 2. Deploy
- **Push to main branch** → Automatic deployment
- **Pipeline duration**: ~15-20 minutes
- **Cost**: $80/month primary + $65/month DR (when enabled)

## 📊 Features

### Application
- **Visitor Tracking**: IP, location, browser, OS, device
- **Real-time Dashboard**: Live analytics with auto-refresh
- **REST API**: Programmatic access to visitor data
- **Health Monitoring**: Built-in health checks

### Infrastructure
- **RDS MySQL**: Managed database (t3.micro, 20GB)
- **ECS Fargate**: Serverless containers with auto-scaling
- **Application Load Balancer**: High availability
- **AWS Secrets Manager**: Secure credential management
- **Disaster Recovery**: Cross-region replication ready

### CI/CD Pipeline
- **GitHub Actions**: Automated CI/CD pipeline
- **Terraform**: Infrastructure as Code
- **Docker**: Containerized application
- **Automated Testing**: Health, API, and application tests
- **Zero Manual Steps**: Fully automated deployment

## 💰 Cost Optimization

### Primary Region (eu-west-1)
- RDS MySQL t3.micro: ~$15/month
- ECS Fargate (2 tasks): ~$15/month
- Application Load Balancer: ~$18/month
- NAT Gateway: ~$32/month
- Secrets Manager: ~$0.40/month
- **Total**: ~$80/month

### DR Region (eu-central-1) - Optional
- RDS Read Replica: ~$15/month
- ECS Cluster (0 tasks): $0/month
- ALB (idle): ~$18/month
- NAT Gateway: ~$32/month
- **Total**: ~$65/month

## 🏗️ Architecture

### Primary Infrastructure
- **VPC**: 10.0.0.0/16 with public/private subnets
- **ECS Cluster**: Fargate tasks in private subnets
- **RDS MySQL**: Multi-AZ in private subnets
- **ALB**: Internet-facing load balancer
- **Secrets Manager**: Database credentials

### Disaster Recovery
- **Pilot Light Strategy**: Infrastructure ready, scaled to 0
- **Cross-region Replication**: RDS read replica
- **5-10 minute failover**: Automated promotion

## 🔧 Local Development

### Test Locally
```bash
cd disaster-recovery
docker build -f Dockerfile.apache-rds -t lamp-apache .
docker run -p 8080:80 lamp-apache
# Visit: http://localhost:8080
```

## 📈 Monitoring

### Access Points
- **Application**: http://your-alb-dns-name
- **Health Check**: http://your-alb-dns-name/health.php
- **API**: http://your-alb-dns-name/api.php?action=stats
- **CloudWatch**: AWS Console > CloudWatch

## 🛠️ Pipeline Stages

### 1. Validate (2-3 min)
- Terraform syntax validation
- Code formatting checks

### 2. Build (5-8 min)
- Build Apache Docker image
- Push to ECR with commit SHA

### 3. Deploy (8-12 min)
- Deploy infrastructure with Terraform
- Update ECS service with new image
- Configure auto-scaling and monitoring

### 4. Test (3-5 min)
- Health endpoint testing
- Main application testing
- API endpoint testing

## 🔒 Security

### Network Security
- Private subnets for containers and database
- Security groups with minimal access
- ALB as single entry point

### Application Security
- AWS Secrets Manager for credentials
- IAM roles with least privilege
- Encrypted secrets at rest and in transit

## 📋 Troubleshooting

### Common Issues
1. **Pipeline Failed**: Check GitHub Actions secrets and variables
2. **Health Check Failed**: Check container logs in CloudWatch
3. **Database Connection**: Verify Secrets Manager configuration

### Debug Commands
```bash
# Check Terraform state
cd disaster-recovery
terraform output

# Check ECS service
aws ecs describe-services --cluster lamp-visitor-analytics --services lamp-visitor-analytics

# View logs
aws logs tail /ecs/lamp-visitor-analytics --follow

# Check GitHub Actions workflow status
gh run list --repo your-username/visitor-analytics
```

## 🎯 Project Structure

```
lamp-visitor-analytics/
├── disaster-recovery/          # Main Terraform infrastructure
│   ├── modules/               # Terraform modules
│   │   ├── networking/        # VPC, subnets, routing
│   │   ├── security/          # Security groups
│   │   ├── rds/              # MySQL database
│   │   ├── ecs/              # Container platform
│   │   ├── ecr/              # Container registry
│   │   └── secrets/          # Secrets management
│   ├── scripts/              # Deployment scripts
│   ├── src/                  # PHP application
│   └── *.tf                  # Terraform configuration
├── archive/                   # Old ECS CLI implementation
├── src/                      # Application source (original)
├── apache-config/            # Apache configuration
└── .github/workflows/       # GitHub Actions workflows
    └── deploy.yml           # Main CI/CD pipeline
```

## 🚨 Disaster Recovery

### Enable DR
Set GitHub Actions variable: `ENABLE_DR = "true"`

### Failover Process
```bash
cd disaster-recovery
./scripts/failover.sh
```

### Recovery Time
- **RTO**: 5-10 minutes (automated)
- **RPO**: Near real-time (read replica lag)

## 🎉 Success Metrics

After deployment:
- ✅ Fully automated CI/CD pipeline
- ✅ Cost-optimized infrastructure
- ✅ Managed MySQL database with RDS
- ✅ Secure credential management
- ✅ Auto-scaling application (1-6 tasks)
- ✅ Disaster recovery ready
- ✅ Comprehensive monitoring and testing

**Total setup time**: ~20 minutes
**Monthly cost**: $80 primary + $65 DR (optional)
**Deployment time**: ~20 minutes per update