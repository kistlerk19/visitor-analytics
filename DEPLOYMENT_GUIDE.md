# Complete Deployment & Disaster Recovery Guide

## 🚀 **Deployment Process**

### **Phase 1: Pre-Deployment Setup**

#### **1.1 GitLab Configuration**
```bash
# GitLab CI/CD Variables (Settings > CI/CD > Variables)
AWS_ACCESS_KEY_ID = "AKIA..."           # AWS Access Key
AWS_SECRET_ACCESS_KEY = "..."           # AWS Secret Key  
AWS_ACCOUNT_ID = "123456789012"         # 12-digit AWS Account ID
NOTIFICATION_EMAIL = "admin@domain.com" # Email for notifications
ENABLE_DR = "true"                     # Set to "true" for DR
```

#### **1.2 Repository Setup**
```bash
# Clone/Fork repository
git clone <repository-url>
cd visitor-analytics

# Verify structure
ls -la disaster-recovery/
```

### **Phase 2: Automated Deployment**

#### **2.1 Deployment Trigger**
```bash
# Push to main branch triggers automatic deployment
git add .
git commit -m "Deploy LAMP stack with DR"
git push origin main
```

#### **2.2 Pipeline Execution**
```yaml
# Pipeline Stages (15-20 minutes total)
Stage 1: Validate    (2-3 min)  - Terraform validation
Stage 2: Build       (5-8 min)  - Docker image build & push
Stage 3: Deploy      (8-12 min) - Infrastructure deployment
Stage 4: Test        (3-5 min)  - Health checks & validation
```

### **Phase 3: Infrastructure Creation**

#### **3.1 Networking Infrastructure**
```hcl
# Created Resources:
- VPC (11.0.0.0/16)
- Internet Gateway
- NAT Gateway (1x in AZ-a)
- Public Subnets (2x across AZs)
- Private Subnets (2x across AZs)
- Route Tables (Public & Private)
- Security Groups (ALB, ECS, RDS)
```

#### **3.2 Compute Infrastructure**
```hcl
# ECS Resources:
- ECS Cluster (Fargate)
- Task Definition (512 CPU, 1GB RAM)
- ECS Service (2 tasks, auto-scaling 1-6)
- Application Load Balancer
- Target Group (health checks on /health.php)
- CloudWatch Log Group (/ecs/visitor-analytics)
```

#### **3.3 Data Infrastructure**
```hcl
# Database Resources:
- RDS MySQL (db.t3.micro, 20GB GP2)
- DB Subnet Group (private subnets)
- Random Password Generation
- Secrets Manager (encrypted credentials)
- Cross-region replication (if DR enabled)
```

#### **3.4 Container Infrastructure**
```hcl
# Container Resources:
- ECR Repository (lamp-apache)
- Docker Image (PHP 8.1 + Apache)
- Lifecycle Policy (keep 5 images)
- IAM Roles (execution & task roles)
```

## 🔄 **Deployment Flow Detailed**

### **Step 1: Terraform Validation**
```bash
# What happens:
cd disaster-recovery/
terraform init -backend=false
terraform validate
terraform fmt -check

# Validates:
- Terraform syntax correctness
- Module dependencies
- Variable definitions
- Resource configurations
```

### **Step 2: Docker Build & Push**
```bash
# What happens:
aws ecr get-login-password | docker login
docker build -f Dockerfile.apache-rds -t lamp-apache .
docker tag lamp-apache:latest $ECR_REPO:$COMMIT_SHA
docker push $ECR_REPO:$COMMIT_SHA

# Creates:
- Apache + PHP 8.2 container
- Application code included
- Secrets Manager integration
- Health check endpoints
```

### **Step 3: Infrastructure Deployment**
```bash
# What happens:
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# Deploys in order:
1. Networking (VPC, subnets, gateways)
2. Security (security groups, IAM roles)
3. Data (RDS, Secrets Manager)
4. Compute (ECS cluster, service)
5. Load Balancing (ALB, target groups)
```

### **Step 4: Application Testing**
```bash
# What happens:
ALB_DNS=$(terraform output -raw primary_alb_dns)
curl -f http://$ALB_DNS/health.php
curl -f http://$ALB_DNS/
curl -f http://$ALB_DNS/api.php?action=stats

# Tests:
- Health endpoint (JSON response)
- Main application (visitor tracking)
- API endpoint (statistics)
- Database connectivity
```

## 🚨 **Disaster Recovery Process**

### **DR Architecture Overview**
```
PRIMARY REGION (eu-west-1)     DR REGION (eu-central-1)
┌─────────────────────────┐    ┌─────────────────────────┐
│ ✅ Active Application   │    │ ⏸️  Standby Application │
│ ✅ Active Database      │───▶│ 📋 Read Replica        │
│ ✅ 2 ECS Tasks         │    │ 🛑 0 ECS Tasks         │
│ 💰 ~$80/month          │    │ 💰 ~$65/month          │
└─────────────────────────┘    └─────────────────────────┘
```

### **DR Activation Methods**

#### **Method 1: Automatic DR (Recommended)**
```bash
# Set GitLab CI variable
ENABLE_DR = "true"

# Push to main branch
git push origin main

# Pipeline automatically:
1. Creates DR infrastructure
2. Sets up RDS read replica
3. Replicates container images
4. Configures cross-region secrets
```

#### **Method 2: Manual DR Scripts**
```bash
# Enable DR infrastructure
cd disaster-recovery
./scripts/enable-dr.sh

# In case of disaster, activate failover
./scripts/failover.sh
```

### **DR Failover Process (5-10 minutes)**

#### **Step 1: Detect Disaster**
```bash
# Monitoring indicators:
- Primary ALB health checks failing
- RDS instance unavailable
- ECS service unable to start tasks
- CloudWatch alarms triggered
```

#### **Step 2: Promote Read Replica**
```bash
# Automatic process:
aws rds promote-read-replica \
  --db-instance-identifier visitor-analytics-db-replica \
  --region eu-central-1

# Wait for promotion (2-3 minutes)
aws rds wait db-instance-available \
  --db-instance-identifier visitor-analytics-db-replica
```

#### **Step 3: Scale Up DR Application**
```bash
# Scale ECS service from 0 to 2 tasks
aws ecs update-service \
  --cluster visitor-analytics \
  --service visitor-analytics \
  --desired-count 2 \
  --region eu-central-1

# Wait for service stability (2-3 minutes)
aws ecs wait services-stable \
  --cluster visitor-analytics \
  --services visitor-analytics
```

#### **Step 4: Update DNS (Manual)**
```bash
# Update Route 53 or DNS provider
# Point domain to DR ALB DNS name
OLD_ALB: lamp-alb-123456789.eu-west-1.elb.amazonaws.com
NEW_ALB: lamp-alb-987654321.eu-central-1.elb.amazonaws.com
```

### **DR Testing & Validation**

#### **Regular DR Drills**
```bash
# Monthly DR test (non-disruptive)
cd disaster-recovery

# 1. Verify DR infrastructure
terraform plan -var="enable_dr=true"

# 2. Test read replica lag
aws rds describe-db-instances \
  --db-instance-identifier visitor-analytics-db-replica \
  --query 'DBInstances[0].ReadReplicaDBInstanceIdentifiers'

# 3. Test application in DR region
DR_ALB=$(terraform output -raw dr_alb_dns)
curl -f http://$DR_ALB/health.php

# 4. Verify data consistency
# Compare visitor counts between primary and replica
```

#### **Failback Process**
```bash
# After primary region recovery:

# 1. Sync data from DR to primary (if needed)
# 2. Scale down DR region to 0 tasks
# 3. Update DNS back to primary region
# 4. Verify primary region functionality
# 5. Re-establish read replica
```

## 📊 **Monitoring & Observability**

### **CloudWatch Metrics**
```bash
# Key metrics to monitor:
- ECS Service CPU/Memory utilization
- ALB request count and latency
- RDS connections and performance
- Auto scaling events
- Health check success rate
```

### **Log Aggregation**
```bash
# Log locations:
/ecs/visitor-analytics/apache/task-id
/aws/rds/instance/visitor-analytics-db/error
/aws/applicationloadbalancer/visitor-analytics-alb
```

### **Alerting Setup**
```bash
# Recommended CloudWatch alarms:
- ECS Service unhealthy tasks > 0
- ALB 5xx error rate > 5%
- RDS CPU utilization > 80%
- RDS read replica lag > 60 seconds
```

## 💰 **Cost Management**

### **Cost Optimization Strategies**
```bash
# Implemented optimizations:
✅ RDS t3.micro (smallest instance)
✅ No RDS backups (dev/test environment)
✅ 20GB storage (minimal size)
✅ 3-day log retention
✅ Pilot light DR (0 running tasks)
✅ Lifecycle policies for ECR images
```

### **Monthly Cost Breakdown**
```
PRIMARY REGION (eu-west-1):
├── RDS MySQL t3.micro      $15.00
├── ECS Fargate (2 tasks)   $15.00
├── Application Load Balancer $18.00
├── NAT Gateway             $32.00
├── Secrets Manager         $0.40
└── CloudWatch Logs         $2.00
    SUBTOTAL: ~$82.40/month

DR REGION (eu-central-1) - Optional:
├── RDS Read Replica        $15.00
├── ECS Fargate (0 tasks)   $0.00
├── Application Load Balancer $18.00
├── NAT Gateway             $32.00
├── Secrets Manager         $0.40
└── CloudWatch Logs         $1.00
    SUBTOTAL: ~$66.40/month

TOTAL WITH DR: ~$148.80/month
```

## 🔧 **Troubleshooting Guide**

### **Common Issues & Solutions**

#### **Issue 1: ECS Tasks Not Starting**
```bash
# Diagnosis:
aws ecs describe-services --cluster visitor-analytics --services visitor-analytics
aws logs tail /ecs/visitor-analytics --follow

# Common causes:
- Secrets Manager permissions
- Security group misconfiguration
- Image pull errors
- Resource constraints

# Solutions:
- Check IAM roles and policies
- Verify security group rules
- Confirm ECR image exists
- Review task definition resources
```

#### **Issue 2: Database Connection Failures**
```bash
# Diagnosis:
aws secretsmanager get-secret-value --secret-id visitor-analytics-db-credentials
aws rds describe-db-instances --db-instance-identifier visitor-analytics-db

# Common causes:
- Incorrect database endpoint
- Security group blocking access
- Secrets Manager configuration
- Database not available

# Solutions:
- Update database endpoint in secrets
- Check RDS security group rules
- Verify secrets format and content
- Wait for RDS availability
```

#### **Issue 3: Health Checks Failing**
```bash
# Diagnosis:
ALB_DNS=$(terraform output -raw primary_alb_dns)
curl -v http://$ALB_DNS/health.php

# Common causes:
- Application not responding
- Database connectivity issues
- Load balancer misconfiguration
- Target group health check settings

# Solutions:
- Check application logs
- Verify database connection
- Review ALB target group settings
- Adjust health check parameters
```

## 🎯 **Success Criteria**

### **Deployment Success Indicators**
- ✅ All pipeline stages complete successfully
- ✅ Application accessible via ALB DNS
- ✅ Health endpoint returns HTTP 200
- ✅ Database connectivity confirmed
- ✅ Auto-scaling policies active
- ✅ CloudWatch logs streaming

### **DR Success Indicators**
- ✅ DR infrastructure deployed
- ✅ RDS read replica synchronized
- ✅ Cross-region secrets replicated
- ✅ DR failover completes in <10 minutes
- ✅ Application functional in DR region
- ✅ Data consistency maintained

### **Performance Benchmarks**
- 🎯 Application response time: <500ms
- 🎯 Health check success rate: >99%
- 🎯 Auto-scaling response time: <5 minutes
- 🎯 RDS read replica lag: <30 seconds
- 🎯 DR failover time: <10 minutes