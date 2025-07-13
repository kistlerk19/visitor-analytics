# Disaster Recovery Runbook

## 🚨 **Emergency Response Procedures**

### **Incident Classification**

#### **Level 1: Service Degradation**
- Some users experiencing issues
- Partial functionality available
- Response time: 30 minutes

#### **Level 2: Service Outage**
- Complete service unavailable
- All users affected
- Response time: 15 minutes

#### **Level 3: Regional Disaster**
- Entire AWS region unavailable
- Infrastructure destroyed
- Response time: 5 minutes (immediate DR activation)

## 🔍 **Disaster Detection**

### **Automated Monitoring**
```bash
# CloudWatch Alarms (Auto-trigger)
- ALB 5xx errors > 50% for 5 minutes
- ECS service running tasks = 0 for 3 minutes
- RDS instance status != available for 2 minutes
- Health check failures > 90% for 5 minutes
```

### **Manual Detection Checklist**
```bash
# Primary Health Checks
□ Application URL accessible: http://$(terraform output -raw primary_alb_dns)
□ Health endpoint responding: /health.php returns HTTP 200
□ Database connectivity: API returns visitor statistics
□ ECS tasks running: aws ecs describe-services shows desired=running
□ RDS instance available: aws rds describe-db-instances shows available
```

## ⚡ **Emergency DR Activation**

### **Immediate Response (0-5 minutes)**

#### **Step 1: Assess Situation**
```bash
# Quick status check
cd disaster-recovery/
export PRIMARY_ALB=$(terraform output -raw primary_alb_dns)
export DR_ALB=$(terraform output -raw dr_alb_dns)

# Test primary region
curl -f http://$PRIMARY_ALB/health.php || echo "PRIMARY FAILED"

# Test DR region availability
curl -f http://$DR_ALB/health.php || echo "DR NOT READY"
```

#### **Step 2: Activate DR (Automated)**
```bash
# Execute failover script
./scripts/failover.sh

# Script performs:
# 1. Promotes RDS read replica (2-3 min)
# 2. Scales ECS service 0→2 tasks (1-2 min)
# 3. Validates application health (1 min)
# 4. Outputs new endpoints
```

#### **Step 3: DNS Cutover (Manual)**
```bash
# Update DNS records immediately
# Route 53 or your DNS provider:
OLD: lamp-alb-xxx.eu-west-1.elb.amazonaws.com
NEW: lamp-alb-xxx.eu-central-1.elb.amazonaws.com

# TTL should be ≤ 300 seconds for fast propagation
```

### **Detailed DR Activation Steps**

#### **Phase 1: Database Failover (2-3 minutes)**
```bash
# Promote read replica to primary
aws rds promote-read-replica \
  --db-instance-identifier lamp-visitor-analytics-db-replica \
  --region eu-central-1

# Monitor promotion progress
aws rds describe-db-instances \
  --db-instance-identifier lamp-visitor-analytics-db-replica \
  --region eu-central-1 \
  --query 'DBInstances[0].DBInstanceStatus'

# Wait for 'available' status
aws rds wait db-instance-available \
  --db-instance-identifier lamp-visitor-analytics-db-replica \
  --region eu-central-1
```

#### **Phase 2: Application Failover (1-2 minutes)**
```bash
# Scale up ECS service in DR region
aws ecs update-service \
  --cluster lamp-visitor-analytics \
  --service lamp-visitor-analytics \
  --desired-count 2 \
  --region eu-central-1

# Monitor service scaling
aws ecs describe-services \
  --cluster lamp-visitor-analytics \
  --services lamp-visitor-analytics \
  --region eu-central-1 \
  --query 'services[0].{desired:desiredCount,running:runningCount,pending:pendingCount}'

# Wait for service stability
aws ecs wait services-stable \
  --cluster lamp-visitor-analytics \
  --services lamp-visitor-analytics \
  --region eu-central-1
```

#### **Phase 3: Validation (1 minute)**
```bash
# Test DR application
export DR_ALB=$(terraform output -raw dr_alb_dns)

# Health check
curl -f http://$DR_ALB/health.php | jq '.'
# Expected: {"status":"healthy","database":"connected","timestamp":"..."}

# Application test
curl -f http://$DR_ALB/ | grep -q "Visitor Analytics"
# Expected: HTML page loads successfully

# API test
curl -f http://$DR_ALB/api.php?action=stats | jq '.total_visitors'
# Expected: Number of visitors returned
```

## 📋 **DR Activation Checklist**

### **Pre-Activation Checklist**
```bash
□ Confirm primary region is truly unavailable
□ Verify DR infrastructure is healthy
□ Check RDS read replica is synchronized
□ Ensure DR region has latest container images
□ Validate secrets are replicated to DR region
□ Confirm team is notified of DR activation
```

### **During Activation Checklist**
```bash
□ Execute failover script: ./scripts/failover.sh
□ Monitor RDS replica promotion progress
□ Watch ECS service scaling in DR region
□ Update DNS records to point to DR ALB
□ Test application functionality in DR region
□ Verify database connectivity and data integrity
□ Update monitoring dashboards to DR region
□ Communicate status to stakeholders
```

### **Post-Activation Checklist**
```bash
□ Application fully functional in DR region
□ All critical features working
□ Performance metrics within acceptable range
□ Monitoring and alerting configured for DR region
□ Incident documentation started
□ Stakeholder communication sent
□ Primary region recovery planning initiated
```

## 🔄 **Failback Procedures**

### **When to Failback**
- Primary region fully restored and tested
- Root cause identified and resolved
- Planned maintenance window available
- Data synchronization completed

### **Failback Process**

#### **Step 1: Prepare Primary Region**
```bash
# Verify primary region health
cd disaster-recovery/
terraform plan -target=module.primary_ecs
terraform apply -target=module.primary_ecs

# Test primary region
export PRIMARY_ALB=$(terraform output -raw primary_alb_dns)
curl -f http://$PRIMARY_ALB/health.php
```

#### **Step 2: Data Synchronization**
```bash
# Create new read replica from DR (now primary) to original primary region
aws rds create-db-instance-read-replica \
  --db-instance-identifier lamp-visitor-analytics-db-failback \
  --source-db-instance-identifier lamp-visitor-analytics-db-replica \
  --source-region eu-central-1 \
  --region eu-west-1

# Wait for replica creation and sync
aws rds wait db-instance-available \
  --db-instance-identifier lamp-visitor-analytics-db-failback \
  --region eu-west-1
```

#### **Step 3: Promote and Switch**
```bash
# Promote failback replica to primary
aws rds promote-read-replica \
  --db-instance-identifier lamp-visitor-analytics-db-failback \
  --region eu-west-1

# Update application to use original primary region
# Scale up primary region ECS service
aws ecs update-service \
  --cluster lamp-visitor-analytics \
  --service lamp-visitor-analytics \
  --desired-count 2 \
  --region eu-west-1

# Update DNS back to primary region
# Scale down DR region to 0 tasks
aws ecs update-service \
  --cluster lamp-visitor-analytics \
  --service lamp-visitor-analytics \
  --desired-count 0 \
  --region eu-central-1
```

## 📞 **Communication Templates**

### **Initial Incident Notification**
```
SUBJECT: [URGENT] Service Outage - DR Activation in Progress

Team,

We are experiencing a service outage in our primary region (eu-west-1).
Disaster Recovery has been activated in eu-central-1.

Status: DR activation in progress
ETA: Service restoration within 10 minutes
Impact: Complete service unavailability

Updates will be provided every 5 minutes.

Incident Commander: [Name]
```

### **DR Activation Complete**
```
SUBJECT: [UPDATE] Service Restored via Disaster Recovery

Team,

Disaster Recovery activation is complete. Service has been restored.

Status: Service operational in DR region (eu-central-1)
New URL: http://[DR-ALB-DNS]
Impact: Service fully restored

Next Steps:
- Monitor DR region performance
- Investigate primary region failure
- Plan failback when primary region is restored

Incident Commander: [Name]
```

### **Failback Complete**
```
SUBJECT: [RESOLVED] Service Restored to Primary Region

Team,

Failback to primary region is complete. All systems operational.

Status: Service operational in primary region (eu-west-1)
URL: http://[PRIMARY-ALB-DNS]
Impact: None - service fully restored

Post-incident review scheduled for [Date/Time].

Incident Commander: [Name]
```

## 🔧 **Troubleshooting During DR**

### **Common DR Issues**

#### **Issue: RDS Replica Promotion Fails**
```bash
# Symptoms:
- Promotion command returns error
- Replica status stuck in 'modifying'

# Diagnosis:
aws rds describe-db-instances \
  --db-instance-identifier lamp-visitor-analytics-db-replica \
  --region eu-central-1

# Solutions:
1. Wait for any pending modifications to complete
2. Check for active connections and terminate if needed
3. Retry promotion command
4. If persistent, create new DB from snapshot
```

#### **Issue: ECS Tasks Won't Start in DR**
```bash
# Symptoms:
- Desired count increases but running count stays 0
- Tasks start then immediately stop

# Diagnosis:
aws ecs describe-services \
  --cluster lamp-visitor-analytics \
  --services lamp-visitor-analytics \
  --region eu-central-1

aws logs tail /ecs/lamp-visitor-analytics --region eu-central-1

# Solutions:
1. Check secrets manager access in DR region
2. Verify security group rules
3. Confirm container image exists in DR ECR
4. Review task definition configuration
```

#### **Issue: Application Can't Connect to Database**
```bash
# Symptoms:
- Health check returns database connection error
- Application shows 500 errors

# Diagnosis:
# Check secrets in DR region
aws secretsmanager get-secret-value \
  --secret-id lamp-visitor-analytics-db-credentials \
  --region eu-central-1

# Solutions:
1. Update secrets with new database endpoint
2. Verify security group allows ECS→RDS connection
3. Check database status and availability
4. Restart ECS tasks to pick up new secrets
```

## 📊 **DR Performance Metrics**

### **Target Metrics**
- **RTO (Recovery Time Objective)**: 10 minutes
- **RPO (Recovery Point Objective)**: 5 minutes
- **Availability Target**: 99.9% (8.76 hours downtime/year)

### **Actual Performance Tracking**
```bash
# Metrics to measure during DR:
- Time to detect incident: Target <2 minutes
- Time to activate DR: Target <5 minutes
- Time to DNS propagation: Target <5 minutes
- Application response time in DR: Target <1 second
- Data loss (if any): Target <5 minutes of data
```

### **Post-DR Analysis**
```bash
# Questions to answer:
1. What was the root cause of the outage?
2. How long did detection take?
3. Was DR activation smooth?
4. Were there any data consistency issues?
5. What can be improved for next time?
```

## 🎯 **DR Testing Schedule**

### **Monthly DR Drill**
- Test read replica lag and data consistency
- Verify DR infrastructure health
- Practice failover procedures (non-production)
- Update runbook based on findings

### **Quarterly Full DR Test**
- Complete failover to DR region
- Run full application test suite
- Measure RTO/RPO performance
- Test failback procedures
- Update team training

### **Annual DR Review**
- Review and update DR strategy
- Assess cost vs. benefit
- Update RTO/RPO targets
- Review and update runbook
- Conduct team training session