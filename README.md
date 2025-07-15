# Enterprise Visitor Analytics Platform
## LAMP Stack with Terraform, Disaster Recovery & AWS Automation

[![Deploy Status](https://github.com/your-username/visitor-analytics/workflows/Deploy%20LAMP%20Stack%20with%20Disaster%20Recovery/badge.svg)](https://github.com/your-username/visitor-analytics/actions)
[![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-623CE4)](https://terraform.io)
[![Platform](https://img.shields.io/badge/Platform-AWS-FF9900)](https://aws.amazon.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-ready, cost-optimized visitor analytics platform built with containerized LAMP stack, featuring automated CI/CD deployment, disaster recovery, and enterprise-grade monitoring.

## 🚀 Quick Deployment

### Prerequisites
- AWS Account with programmatic access
- GitHub repository (fork this project)
- Domain name (optional, for custom DNS)

### 1. GitHub Configuration
**Repository Secrets** (Settings → Secrets and variables → Actions → Repository secrets):
```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=wJalrXUt...
AWS_ACCOUNT_ID=123456789012
NOTIFICATION_EMAIL=admin@yourdomain.com
```

**Repository Variables** (Settings → Secrets and variables → Actions → Repository variables):
```bash
ENABLE_DR=false          # Set to "true" for disaster recovery
DOMAIN_NAME=             # Optional: your-domain.com
```

### 2. Automated Deployment
```bash
git push origin main      # Triggers automatic deployment
```

**Deployment Timeline:**
- ⏱️ **Total Duration**: 15-20 minutes
- 💰 **Monthly Cost**: $80 (primary) + $65 (DR when enabled)
- 🎯 **Zero Manual Steps**: Fully automated infrastructure provisioning

## 🏗️ System Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet Gateway                          │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                Application Load Balancer                        │
│                    (Multi-AZ)                                   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼────┐       ┌───▼────┐       ┌───▼────┐
│Private │       │Private │       │Private │
│Subnet  │       │Subnet  │       │Subnet  │
│AZ-1a   │       │AZ-1b   │       │AZ-1c   │
│        │       │        │       │        │
│ECS     │       │ECS     │       │RDS     │
│Tasks   │       │Tasks   │       │MySQL   │
└────────┘       └────────┘       └────────┘
```

### Component Details

#### Primary Region (eu-west-1)
- **VPC**: 10.0.0.0/16 with 3 AZs
- **Public Subnets**: ALB, NAT Gateway
- **Private Subnets**: ECS Fargate, RDS MySQL
- **Security**: WAF, Security Groups, NACLs

#### Disaster Recovery Region (eu-central-1)
- **Pilot Light Strategy**: Infrastructure ready, scaled to 0
- **RDS Read Replica**: Cross-region replication
- **Automated Failover**: Lambda-triggered promotion

## 📊 Application Features

### Core Functionality
- **Real-time Visitor Tracking**: IP geolocation, browser fingerprinting
- **Analytics Dashboard**: Live metrics with auto-refresh
- **REST API**: Programmatic data access
- **Health Monitoring**: Multi-layer health checks

### Technical Stack
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Backend**: PHP 8.1, Apache 2.4
- **Database**: MySQL 8.0 (RDS)
- **Container**: Docker with multi-stage builds
- **Infrastructure**: Terraform, AWS ECS Fargate

### API Endpoints
```bash
GET  /                           # Main dashboard
GET  /health.php                 # Health check endpoint
GET  /api.php?action=stats       # Visitor statistics
GET  /api.php?action=recent      # Recent visitors
POST /api.php?action=track       # Manual visitor tracking
```

## 💰 Cost Analysis

### Primary Region Breakdown (eu-west-1)
| Service | Instance Type | Monthly Cost | Annual Cost |
|---------|---------------|--------------|-------------|
| RDS MySQL | t3.micro | $15.00 | $180.00 |
| ECS Fargate | 2 tasks × 0.25 vCPU | $15.00 | $180.00 |
| Application Load Balancer | Standard | $18.00 | $216.00 |
| NAT Gateway | Single AZ | $32.00 | $384.00 |
| Secrets Manager | 1 secret | $0.40 | $4.80 |
| CloudWatch Logs | Standard retention | $2.00 | $24.00 |
| **Total Primary** | | **$82.40** | **$988.80** |

### Disaster Recovery Region (eu-central-1)
| Service | Instance Type | Monthly Cost | Annual Cost |
|---------|---------------|--------------|-------------|
| RDS Read Replica | t3.micro | $15.00 | $180.00 |
| ECS Cluster | 0 tasks (standby) | $0.00 | $0.00 |
| Application Load Balancer | Idle | $18.00 | $216.00 |
| NAT Gateway | Single AZ | $32.00 | $384.00 |
| Lambda Functions | DR automation | $1.00 | $12.00 |
| **Total DR** | | **$66.00** | **$792.00** |

### Cost Optimization Features
- **Auto-scaling**: 1-6 tasks based on CPU/memory
- **Spot instances**: Not used (Fargate limitation)
- **Reserved capacity**: Available for RDS (30% savings)
- **Data transfer**: Optimized with CloudFront (optional)

## 🔧 Local Development

### Development Setup
```bash
# Clone repository
git clone https://github.com/your-username/visitor-analytics.git
cd visitor-analytics

# Build and run locally
cd disaster-recovery
docker build -f Dockerfile.apache-rds -t visitor-analytics .
docker run -p 8080:80 visitor-analytics

# Access application
open http://localhost:8080
```

### Testing Endpoints
```bash
# Health check
curl http://localhost:8080/health.php

# API statistics
curl http://localhost:8080/api.php?action=stats

# Recent visitors
curl http://localhost:8080/api.php?action=recent&limit=10
```

## 🚨 Disaster Recovery Operations

### Emergency Kill Switch
**Immediate failover to DR region:**
```bash
# Set kill switch variable in Terraform
cd disaster-recovery
terraform apply -var="dr_killswitch=true" -auto-approve
```

**What happens:**
1. Primary region scaled to 0 tasks
2. DR region scaled to 2 tasks
3. RDS read replica promoted
4. DNS updated (if Route53 configured)

### Automated Failover
```bash
# Trigger automated DR failover
cd disaster-recovery/scripts
./automated-failover.sh
```

**Failover Process:**
1. Health check validation
2. Lambda-triggered promotion
3. ECS service scaling
4. DNS failover (optional)
5. Notification alerts

### Manual Failover
```bash
# Step-by-step manual failover
cd disaster-recovery/scripts
./failover.sh
```

### Failback to Primary
```bash
# Return to primary region
cd disaster-recovery/scripts
./failback.sh
```

## 🧹 Infrastructure Cleanup

### Complete Cleanup (All Resources)
```bash
# WARNING: This deletes everything
./cleanup-all.sh
```

### Remote State Cleanup
```bash
# Clean up remote Terraform state
export AWS_ACCOUNT_ID=123456789012
./destroy-remote.sh
```

### Selective Cleanup
```bash
# Disable DR only
cd disaster-recovery
terraform apply -var="enable_dr=false" -auto-approve

# Scale to zero (keep infrastructure)
terraform apply -var="ecs_desired_count=0" -auto-approve
```

## 🛠️ CI/CD Pipeline

### Pipeline Stages
1. **Validate** (2-3 min)
   - Terraform syntax validation
   - Code formatting checks
   - Security scanning

2. **Build** (5-8 min)
   - Docker image build
   - ECR repository creation
   - Image push with SHA tags

3. **Deploy** (8-12 min)
   - Infrastructure provisioning
   - ECS service updates
   - Auto-scaling configuration

4. **Test** (3-5 min)
   - Health endpoint validation
   - Application functionality tests
   - API endpoint verification

5. **DR Setup** (Optional, 5-10 min)
   - Cross-region replication
   - Lambda function deployment
   - Monitoring setup

### Pipeline Triggers
- **Push to main**: Full deployment
- **Pull request**: Validation only
- **Manual trigger**: Custom parameters
- **Scheduled**: Weekly DR tests

## 🔒 Security Implementation

### Network Security
- **VPC Isolation**: Private subnets for all compute
- **Security Groups**: Least privilege access
- **NACLs**: Additional network layer protection
- **WAF**: Web application firewall (optional)

### Application Security
- **Secrets Management**: AWS Secrets Manager
- **IAM Roles**: Task-specific permissions
- **Encryption**: At rest and in transit
- **Input Validation**: SQL injection prevention

### Compliance Features
- **Audit Logging**: CloudTrail integration
- **Access Control**: IAM policies
- **Data Privacy**: IP anonymization options
- **Backup Strategy**: Automated RDS snapshots

## 📈 Monitoring & Observability

### CloudWatch Metrics
- **Application**: Response time, error rates
- **Infrastructure**: CPU, memory, network
- **Database**: Connections, query performance
- **Custom**: Visitor counts, geographic distribution

### Alerting
- **Health Check Failures**: Immediate notification
- **High Error Rates**: 5xx responses > 5%
- **Resource Utilization**: CPU > 80%
- **DR Events**: Failover notifications

### Log Aggregation
```bash
# View application logs
aws logs tail /ecs/visitor-analytics --follow

# View ALB access logs
aws logs tail /aws/applicationloadbalancer/app/visitor-analytics

# View RDS logs
aws logs tail /aws/rds/instance/visitor-analytics-db/error
```

## 🎯 Project Structure

```
visitor-analytics/
├── .github/workflows/           # CI/CD pipelines
│   └── deploy.yml              # Main deployment workflow
├── disaster-recovery/          # Primary Terraform configuration
│   ├── modules/               # Reusable Terraform modules
│   │   ├── networking/        # VPC, subnets, routing
│   │   ├── security/          # Security groups, IAM
│   │   ├── rds/              # MySQL database
│   │   ├── ecs/              # Container orchestration
│   │   ├── ecr/              # Container registry
│   │   ├── lambda/           # DR automation functions
│   │   ├── route53/          # DNS management
│   │   ├── s3/               # Asset storage
│   │   └── secrets/          # Credential management
│   ├── scripts/              # Operational scripts
│   │   ├── automated-failover.sh
│   │   ├── failback.sh
│   │   ├── test-dr.sh
│   │   └── deploy.sh
│   ├── main.tf               # Primary infrastructure
│   ├── dr.tf                 # Disaster recovery setup
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output values
│   └── Dockerfile.apache-rds # Container definition
├── src/                       # Application source code
│   ├── config/               # Database configuration
│   ├── includes/             # PHP libraries
│   ├── css/                  # Stylesheets
│   ├── js/                   # JavaScript
│   ├── index.php             # Main dashboard
│   ├── api.php               # REST API
│   └── health.php            # Health checks
├── sql/                      # Database schema
├── apache-config/            # Web server configuration
├── cleanup-all.sh            # Complete cleanup script
├── destroy-remote.sh         # Remote state cleanup
└── README.md                 # This documentation
```

## 🔧 Troubleshooting Guide

### Common Issues

#### 1. Deployment Failures
```bash
# Check GitHub Actions logs
gh run list --repo your-username/visitor-analytics
gh run view [run-id] --log

# Verify AWS credentials
aws sts get-caller-identity

# Check Terraform state
cd disaster-recovery
terraform show
```

#### 2. Application Health Issues
```bash
# Check ECS service status
aws ecs describe-services --cluster visitor-analytics --services visitor-analytics

# View container logs
aws logs tail /ecs/visitor-analytics --follow

# Test database connectivity
aws rds describe-db-instances --db-instance-identifier visitor-analytics-db
```

#### 3. DR Failover Problems
```bash
# Verify DR infrastructure
cd disaster-recovery
terraform output dr_alb_dns

# Test DR region connectivity
aws ecs describe-clusters --cluster visitor-analytics --region eu-central-1

# Check RDS replica status
aws rds describe-db-instances --region eu-central-1
```

### Debug Commands
```bash
# Infrastructure status
terraform output
terraform state list

# Service health
curl -I http://$(terraform output -raw primary_alb_dns)/health.php

# Database connection test
mysql -h $(terraform output -raw primary_db_endpoint) -u admin -p

# Container inspection
docker exec -it $(docker ps -q) /bin/bash
```

## 🎉 Success Metrics

### Post-Deployment Validation
- ✅ **Infrastructure**: All resources provisioned successfully
- ✅ **Application**: Dashboard accessible and functional
- ✅ **Database**: Visitor data being tracked and stored
- ✅ **Monitoring**: CloudWatch metrics flowing
- ✅ **Security**: All endpoints secured and encrypted
- ✅ **DR**: Failover tested and operational
- ✅ **CI/CD**: Pipeline executing without errors

### Performance Benchmarks
- **Response Time**: < 200ms (95th percentile)
- **Availability**: 99.9% uptime SLA
- **Scalability**: 1-6 tasks auto-scaling
- **Recovery Time**: < 10 minutes (RTO)
- **Data Loss**: < 5 minutes (RPO)

### Operational Metrics
- **Deployment Time**: ~20 minutes end-to-end
- **Monthly Cost**: $82 primary + $66 DR
- **Maintenance Window**: Zero downtime deployments
- **Security Posture**: No critical vulnerabilities

---

## 📞 Support & Contributing

### Getting Help
- **Issues**: [GitHub Issues](https://github.com/your-username/visitor-analytics/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/visitor-analytics/discussions)
- **Documentation**: [Wiki](https://github.com/your-username/visitor-analytics/wiki)

### Contributing
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for enterprise-grade visitor analytics**