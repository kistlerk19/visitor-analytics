# Disaster Recovery Architecture Diagram

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           DISASTER RECOVERY ARCHITECTURE                        │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│         PRIMARY REGION          │    │           DR REGION             │
│         (eu-west-1)             │    │        (eu-central-1)           │
│                                 │    │                                 │
│  ┌─────────────────────────────┐│    │┌─────────────────────────────┐  │
│  │         INTERNET            ││    ││         INTERNET            │  │
│  └─────────────┬───────────────┘│    │└─────────────┬───────────────┘  │
│                │                │    │              │                  │
│  ┌─────────────▼───────────────┐│    │┌─────────────▼───────────────┐  │
│  │    Application Load         ││    ││    Application Load         │  │
│  │       Balancer              ││    ││       Balancer              │  │
│  │      (ACTIVE)               ││    ││      (STANDBY)              │  │
│  └─────────────┬───────────────┘│    │└─────────────┬───────────────┘  │
│                │                │    │              │                  │
│  ┌─────────────▼───────────────┐│    │┌─────────────▼───────────────┐  │
│  │        ECS Cluster          ││    ││        ECS Cluster          │  │
│  │      (2 Tasks Running)      ││    ││      (0 Tasks - Pilot)      │  │
│  │                             ││    ││                             │  │
│  │  ┌─────┐    ┌─────┐         ││    ││  ┌─────┐    ┌─────┐         │  │
│  │  │Task1│    │Task2│         ││    ││  │     │    │     │         │  │
│  │  │LAMP │    │LAMP │         ││    ││  │ OFF │    │ OFF │         │  │
│  │  └─────┘    └─────┘         ││    ││  └─────┘    └─────┘         │  │
│  └─────────────┬───────────────┘│    │└─────────────┬───────────────┘  │
│                │                │    │              │                  │
│  ┌─────────────▼───────────────┐│    │┌─────────────▼───────────────┐  │
│  │       RDS MySQL             ││    ││       RDS MySQL             │  │
│  │      (PRIMARY)              ││◄───┤│    (READ replica)           │  │
│  │                             ││    ││                             │  │
│  │  • Multi-AZ                 ││    ││  • Cross-region replica     │  │
│  │  • Automated backups        ││    ││  • Promotion ready          │  │
│  │  • 7-day retention          ││    ││  • Real-time sync           │  │
│  └─────────────┬───────────────┘│    │└─────────────────────────────┘  │
│                │                │    │                                 │
│  ┌─────────────▼───────────────┐│    │┌─────────────────────────────┐  │
│  │         S3 Bucket           ││◄───┤│         S3 Bucket           │  │
│  │      (Assets/Backups)       ││    ││      (Replicated)           │  │
│  │                             ││    ││                             │  │
│  │  • Versioning enabled       ││    ││  • Cross-region replication │  │
│  │  • Lifecycle policies       ││    ││  • Standard-IA storage      │  │
│  └─────────────────────────────┘│    │└─────────────────────────────┘  │
│                                 │    │                                 │
└─────────────────────────────────┘    └─────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                            MONITORING & AUTOMATION                              │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│         Lambda Functions        │    │         Route 53 DNS            │
│                                 │    │                                 │
│  ┌─────────────────────────────┐│    │┌─────────────────────────────┐  │
│  │    Health Monitor           ││    ││    Failover Routing         │  │
│  │   (Every 5 minutes)         ││    ││                             │  │
│  └─────────────────────────────┘│    ││  Primary: eu-west-1 ALB     │  │
│                                 │    ││  Secondary: eu-central-1    │  │
│  ┌─────────────────────────────┐│    ││                             │  │
│  │    DR Automation            ││    ││  Health Check: /health.php  │  │
│  │   (Failover Orchestration)  ││    ││  TTL: 60 seconds            │  │
│  └─────────────────────────────┘│    │└─────────────────────────────┘  │
└─────────────────────────────────┘    └─────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                              ALERT SYSTEM                                      │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│         CloudWatch              │    │           SNS Topic             │
│                                 │    │                                 │
│  • ECS Service Health           │    │  • Email Notifications          │
│  • RDS Replication Lag          │    │  • DR Activation Alerts         │
│  • ALB Response Times           │    │  • Health Check Failures        │
│  • Lambda Function Errors       │    │  • Infrastructure Changes       │
└─────────────────────────────────┘    └─────────────────────────────────┘
```

## 🔄 Data Flow Diagrams

### Normal Operations
```
User Request → Route 53 → Primary ALB → ECS Tasks → RDS Primary
                                    ↓
                               S3 Assets (Primary)
                                    ↓
                            Cross-Region Replication
                                    ↓
                               S3 Assets (DR)
                                    ↓
                            RDS Read Replica (DR)
```

### Disaster Recovery Activation
```
Health Monitor → Detects Failure → Lambda DR Function
                                         ↓
                                  Promote RDS Replica
                                         ↓
                                  Scale ECS to 2 Tasks
                                         ↓
                                  Update Route 53 (Optional)
                                         ↓
                                  Send SNS Notifications
```

## 🏗️ Network Architecture

### Primary Region (eu-west-1)
```
VPC: 11.0.0.0/16
├── Public Subnets
│   ├── 11.0.1.0/24 (AZ-a) → ALB
│   └── 11.0.2.0/24 (AZ-b) → ALB
└── Private Subnets
    ├── 11.0.3.0/24 (AZ-a) → ECS Tasks, RDS
    └── 11.0.4.0/24 (AZ-b) → ECS Tasks, RDS
```

### DR Region (eu-central-1)
```
VPC: 10.1.0.0/16
├── Public Subnets
│   ├── 10.1.1.0/24 (AZ-a) → ALB
│   └── 10.1.2.0/24 (AZ-b) → ALB
└── Private Subnets
    ├── 10.1.3.0/24 (AZ-a) → ECS Tasks, RDS Replica
    └── 10.1.4.0/24 (AZ-b) → ECS Tasks, RDS Replica
```

## 🔐 Security Architecture

### Security Groups
```
┌─────────────────────────────────┐
│         ALB Security Group      │
│  • Inbound: 80, 443 from 0.0.0.0/0
│  • Outbound: All to ECS SG      │
└─────────────────────────────────┘
                 ↓
┌─────────────────────────────────┐
│         ECS Security Group      │
│  • Inbound: 80 from ALB SG      │
│  • Outbound: 3306 to RDS SG     │
└─────────────────────────────────┘
                 ↓
┌─────────────────────────────────┐
│         RDS Security Group      │
│  • Inbound: 3306 from ECS SG    │
│  • Outbound: None               │
└─────────────────────────────────┘
```

## 📊 Monitoring Architecture

### Health Check Flow
```
CloudWatch Event (5 min) → Lambda Health Monitor
                                    ↓
                            Check Primary ALB Health
                                    ↓
                            Check DR ALB Health (if enabled)
                                    ↓
                            Publish Results to SNS
                                    ↓
                            Email Notifications
```

### Failover Decision Tree
```
Primary Health Check
        ↓
    [HEALTHY] → Continue Normal Operations
        ↓
   [UNHEALTHY] → Wait 3 Consecutive Failures
        ↓
    Trigger DR Automation Lambda
        ↓
    Promote RDS Read Replica
        ↓
    Scale ECS Service (0 → 2)
        ↓
    Update Route 53 (if configured)
        ↓
    Send Success/Failure Notifications
```

## 🎯 Component Relationships

### Dependencies
```
ECS Tasks → RDS Primary/Replica
ECS Tasks → S3 Assets
ECS Tasks → Secrets Manager
Lambda Functions → ECS Services
Lambda Functions → RDS Instances
Lambda Functions → SNS Topics
Route 53 → ALB Health Checks
CloudWatch → Lambda Triggers
```

### Failover Sequence
```
1. Health Monitor detects failure
2. Lambda DR function triggered
3. RDS replica promoted to primary
4. ECS service scaled up in DR region
5. Health checks verify DR region
6. DNS updated (manual or automatic)
7. Notifications sent to stakeholders
```

This architecture provides:
- **RTO**: 5-10 minutes
- **RPO**: < 1 minute
- **Availability**: 99.9%
- **Cost**: $148/month total
- **Automation**: Fully automated failover
- **Testing**: Non-destructive DR testing