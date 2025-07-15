# Disaster Recovery Runbook

## 🚨 Emergency Response Procedures

### Immediate Response (0-5 minutes)

#### 1. Incident Detection
**Automated Detection:**
- CloudWatch alarms trigger
- Health monitor Lambda detects failures
- SNS notifications sent to on-call team

**Manual Detection:**
- User reports application unavailable
- Monitoring dashboard shows red status
- Direct health check fails

#### 2. Initial Assessment
```bash
# Quick health check
curl -f http://$(terraform output -raw primary_alb_dns)/health-simple.php

# Check ECS service status
aws ecs describe-services --cluster visitor-analytics --services visitor-analytics --region eu-west-1

# Check RDS status
aws rds describe-db-instances --region eu-west-1 --query 'DBInstances[?contains(DBInstanceIdentifier, `visitor-analytics`)].DBInstanceStatus'
```

#### 3. Escalation Decision Matrix

| Severity | Criteria | Response Time | Action |
|----------|----------|---------------|---------|
| **P1 - Critical** | Complete service outage | < 5 minutes | Immediate DR activation |
| **P2 - High** | Partial service degradation | < 15 minutes | Investigate, prepare DR |
| **P3 - Medium** | Performance issues | < 30 minutes | Monitor, troubleshoot |
| **P4 - Low** | Minor issues | < 2 hours | Standard troubleshooting |

### Disaster Recovery Activation (5-15 minutes)

#### Option 1: Automated Failover (Recommended)
```bash
# Navigate to project directory
cd /path/to/visitor-analytics/disaster-recovery

# Execute automated failover
./scripts/automated-failover.sh
```

#### Option 2: Manual Failover
```bash
# Step-by-step manual process
./scripts/failover.sh
```

#### Option 3: Lambda-Triggered Failover
```bash
# Trigger via AWS CLI
aws lambda invoke \
    --function-name visitor-analytics-dr-automation \
    --region eu-west-1 \
    --payload '{"trigger":"manual","reason":"disaster_recovery"}' \
    response.json
```

### Post-Failover Verification (15-20 minutes)

#### 1. Service Health Verification
```bash
# Get DR ALB DNS
DR_ALB=$(terraform output -raw dr_alb_dns)

# Test all endpoints
curl -f "http://$DR_ALB/health-simple.php"
curl -f "http://$DR_ALB/"
curl -f "http://$DR_ALB/api.php?action=stats"
```

#### 2. Database Verification
```bash
# Check promoted database
aws rds describe-db-instances \
    --db-instance-identifier visitor-analytics-db-replica \
    --region eu-central-1 \
    --query 'DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address}'
```

#### 3. Application Functionality Test
```bash
# Run comprehensive test
./scripts/test-dr.sh
```

## 📋 Detailed Procedures

### Pre-Disaster Preparation

#### Monthly DR Testing
```bash
# Schedule: First Sunday of each month at 2 AM
0 2 1 * * /path/to/disaster-recovery/scripts/test-dr.sh >> /var/log/dr-test.log 2>&1
```

#### Quarterly Full DR Exercise
1. **Week 1**: Plan and communicate exercise
2. **Week 2**: Execute full failover during maintenance window
3. **Week 3**: Analyze results and update procedures
4. **Week 4**: Train team on any procedure changes

### Communication Procedures

#### Internal Communication
```
Subject: [P1] DR Activation - LAMP Visitor Analytics

Status: DR ACTIVATED
Time: [TIMESTAMP]
Affected Service: Visitor Analytics Application
DR Region: eu-central-1
Estimated Resolution: [TIME]

Actions Taken:
- Primary region failure confirmed
- DR region activated
- Database replica promoted
- Services scaled up

Next Steps:
- Monitor DR region performance
- Investigate primary region issues
- Plan failback when primary is restored

Contact: [ON-CALL ENGINEER]
```

#### External Communication (if applicable)
```
Subject: Service Maintenance - Visitor Analytics

We are currently performing emergency maintenance on our visitor analytics service. 
The service has been moved to our backup infrastructure and is now operational.

Expected Impact: Minimal - service restored
Timeline: Ongoing monitoring

We apologize for any inconvenience.
```

### Troubleshooting Guide

#### Common Issues and Solutions

**Issue: ECS Tasks Not Starting in DR Region**
```bash
# Check task definition
aws ecs describe-task-definition --task-definition visitor-analytics --region eu-central-1

# Check service events
aws ecs describe-services --cluster visitor-analytics --services visitor-analytics --region eu-central-1 --query 'services[0].events'

# Check container logs
aws logs tail /ecs/visitor-analytics --region eu-central-1 --follow
```

**Issue: Database Connection Failures**
```bash
# Verify RDS endpoint
aws rds describe-db-instances --region eu-central-1 --query 'DBInstances[?contains(DBInstanceIdentifier, `replica`)].Endpoint.Address'

# Check security groups
aws ec2 describe-security-groups --region eu-central-1 --filters "Name=group-name,Values=*rds*"

# Test database connectivity from ECS task
aws ecs execute-command --cluster visitor-analytics --task [TASK-ARN] --container apache --command "/bin/bash" --interactive --region eu-central-1
```

**Issue: Health Checks Failing**
```bash
# Check ALB target health
aws elbv2 describe-target-health --target-group-arn [TG-ARN] --region eu-central-1

# Check ALB configuration
aws elbv2 describe-load-balancers --region eu-central-1 --query 'LoadBalancers[?contains(LoadBalancerName, `lamp`)].DNSName'

# Manual health check
curl -v "http://[DR-ALB-DNS]/health-simple.php"
```

### Failback Procedures

#### When to Failback
- Primary region fully restored and tested
- DR region stable for at least 2 hours
- Business stakeholders approve failback timing
- Maintenance window scheduled (if required)

#### Failback Process
```bash
# 1. Verify primary region health
curl -f "http://$(terraform output -raw primary_alb_dns)/health-simple.php"

# 2. Execute failback
./scripts/failback.sh

# 3. Verify failback success
./scripts/test-dr.sh
```

#### Post-Failback Tasks
1. **Data Synchronization**: Ensure no data loss during DR period
2. **Log Analysis**: Review logs for any issues during DR operation
3. **Performance Monitoring**: Monitor primary region for 24 hours
4. **Documentation Update**: Update runbook with lessons learned

### Recovery Time Objectives

| Component | Target RTO | Actual RTO | Notes |
|-----------|------------|------------|-------|
| **Detection** | 2 minutes | 1-3 minutes | Automated monitoring |
| **Decision** | 3 minutes | 2-5 minutes | Automated or manual |
| **RDS Promotion** | 3 minutes | 2-4 minutes | AWS managed |
| **ECS Scale-up** | 2 minutes | 1-3 minutes | Container startup |
| **Health Verification** | 2 minutes | 1-2 minutes | Automated testing |
| **DNS Update** | 5 minutes | 5-60 minutes | TTL dependent |
| **Total RTO** | **15 minutes** | **10-20 minutes** | End-to-end |

### Recovery Point Objectives

| Data Type | Target RPO | Actual RPO | Notes |
|-----------|------------|------------|-------|
| **Database** | 1 minute | < 30 seconds | Read replica lag |
| **Static Assets** | Real-time | Real-time | S3 CRR |
| **Application State** | N/A | N/A | Stateless |
| **Configuration** | N/A | N/A | IaC managed |

## 📞 Emergency Contacts

### Primary Contacts
- **On-Call Engineer**: [PHONE] / [EMAIL]
- **DevOps Lead**: [PHONE] / [EMAIL]
- **Infrastructure Manager**: [PHONE] / [EMAIL]

### Escalation Path
1. **Level 1**: On-call engineer (0-15 minutes)
2. **Level 2**: DevOps lead (15-30 minutes)
3. **Level 3**: Infrastructure manager (30-60 minutes)
4. **Level 4**: CTO/VP Engineering (60+ minutes)

### External Contacts
- **AWS Support**: [CASE-URL] (Enterprise Support)
- **DNS Provider**: [CONTACT] (if using external DNS)
- **Monitoring Service**: [CONTACT] (if using external monitoring)

## 📊 Post-Incident Review

### Immediate Actions (Within 24 hours)
1. **Incident Timeline**: Document exact sequence of events
2. **Root Cause Analysis**: Identify primary and contributing factors
3. **Impact Assessment**: Quantify business impact and user experience
4. **Response Evaluation**: Assess effectiveness of DR procedures

### Follow-up Actions (Within 1 week)
1. **Process Improvements**: Update procedures based on lessons learned
2. **Technical Improvements**: Implement fixes to prevent recurrence
3. **Training Updates**: Update team training materials
4. **Documentation Updates**: Revise runbooks and procedures

### Metrics to Track
- **Detection Time**: How quickly was the incident detected?
- **Response Time**: How quickly did the team respond?
- **Resolution Time**: How long did it take to restore service?
- **Communication Effectiveness**: Were stakeholders properly informed?
- **Process Adherence**: Were procedures followed correctly?

---

## 🎯 Success Criteria

### DR Activation Success
- ✅ Service restored within RTO (15 minutes)
- ✅ No data loss (RPO < 1 minute)
- ✅ All application functions working
- ✅ Monitoring and alerting operational
- ✅ Stakeholders properly notified

### Failback Success
- ✅ Primary region fully operational
- ✅ DR region returned to pilot light mode
- ✅ No service interruption during failback
- ✅ All monitoring restored to normal
- ✅ Post-incident review completed

This runbook ensures systematic, efficient disaster recovery with minimal downtime and clear communication throughout the process.