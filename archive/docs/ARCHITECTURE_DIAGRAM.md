# LAMP Stack Disaster Recovery Architecture

## 🏗️ **High-Level Architecture Diagram**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                    INTERNET                                         │
└─────────────────────────────┬───────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              ROUTE 53 DNS                                          │
│                         (Failover Routing)                                         │
└─────────────────┬───────────────────────────────────┬───────────────────────────────┘
                  │                                   │
                  ▼                                   ▼
┌─────────────────────────────────────┐    ┌─────────────────────────────────────┐
│         PRIMARY REGION              │    │           DR REGION                 │
│         (eu-west-1)                 │    │        (eu-central-1)               │
│                                     │    │                                     │
│  ┌─────────────────────────────────┐│    │  ┌─────────────────────────────────┐│
│  │        APPLICATION LOAD         ││    │  │        APPLICATION LOAD         ││
│  │         BALANCER (ALB)          ││    │  │         BALANCER (ALB)          ││
│  │      (Internet-facing)          ││    │  │         (Standby)               ││
│  └─────────────┬───────────────────┘│    │  └─────────────┬───────────────────┘│
│                │                    │    │                │                    │
│  ┌─────────────▼───────────────────┐│    │  ┌─────────────▼───────────────────┐│
│  │            VPC                  ││    │  │            VPC                  ││
│  │        (11.0.0.0/16)            ││    │  │        (11.1.0.0/16)            ││
│  │                                 ││    │  │                                 ││
│  │  ┌─────────────────────────────┐││    │  │  ┌─────────────────────────────┐││
│  │  │      PUBLIC SUBNETS         │││    │  │  │      PUBLIC SUBNETS         │││
│  │  │   11.0.1.0/24 (AZ-a)        │││    │  │  │   11.1.1.0/24 (AZ-a)        │││
│  │  │   11.0.2.0/24 (AZ-b)        │││    │  │  │   11.1.2.0/24 (AZ-b)        │││
│  │  │                             │││    │  │  │                             │││
│  │  │  ┌─────────┐  ┌─────────────┐│││    │  │  │  ┌─────────┐  ┌─────────────┐│││
│  │  │  │   IGW   │  │ NAT Gateway ││││    │  │  │  │   IGW   │  │ NAT Gateway ││││
│  │  │  └─────────┘  └─────────────┘│││    │  │  │  └─────────┘  └─────────────┘│││
│  │  └─────────────────────────────┘││    │  │  └─────────────────────────────┘││
│  │                                 ││    │  │                                 ││
│  │  ┌─────────────────────────────┐││    │  │  ┌─────────────────────────────┐││
│  │  │     PRIVATE SUBNETS         │││    │  │  │     PRIVATE SUBNETS         │││
│  │  │   11.0.3.0/24 (AZ-a)        │││    │  │  │   11.1.3.0/24 (AZ-a)        │││
│  │  │   11.0.4.0/24 (AZ-b)        │││    │  │  │   11.1.4.0/24 (AZ-b)        │││
│  │  │                             │││    │  │  │                             │││
│  │  │  ┌─────────────────────────┐│││    │  │  │  ┌─────────────────────────┐│││
│  │  │  │     ECS FARGATE         ││││    │  │  │  │     ECS FARGATE         ││││
│  │  │  │    (2 Tasks Running)    ││││    │  │  │  │    (0 Tasks - Pilot)    ││││
│  │  │  │                         ││││    │  │  │  │                         ││││
│  │  │  │  ┌─────────────────────┐││││    │  │  │  │  ┌─────────────────────┐││││
│  │  │  │  │   Apache Container  │││││    │  │  │  │  │   Apache Container  │││││
│  │  │  │  │   - PHP 8.2         │││││    │  │  │  │  │   - PHP 8.2         │││││
│  │  │  │  │   - Visitor App     │││││    │  │  │  │  │   - Visitor App     │││││
│  │  │  │  │   - Health Checks   │││││    │  │  │  │  │   - Health Checks   │││││
│  │  │  │  └─────────────────────┘││││    │  │  │  │  └─────────────────────┘││││
│  │  │  └─────────────────────────┘│││    │  │  │  └─────────────────────────┘│││
│  │  │                             │││    │  │  │                             │││
│  │  │  ┌─────────────────────────┐│││    │  │  │  ┌─────────────────────────┐│││
│  │  │  │      RDS MYSQL          ││││    │  │  │  │    RDS READ REPLICA     ││││
│  │  │  │    (t3.micro, 20GB)     ││││    │  │  │  │    (t3.micro, 20GB)     ││││
│  │  │  │     Multi-AZ: No        ││││    │  │  │  │   (Standby/Promote)     ││││
│  │  │  │     Backups: No         ││││    │  │  │  │                         ││││
│  │  │  └─────────────────────────┘│││    │  │  │  └─────────────────────────┘│││
│  │  └─────────────────────────────┘││    │  │  └─────────────────────────────┘││
│  └─────────────────────────────────┘│    │  └─────────────────────────────────┘│
│                                     │    │                                     │
│  ┌─────────────────────────────────┐│    │  ┌─────────────────────────────────┐│
│  │       AWS SECRETS MANAGER       ││    │  │       AWS SECRETS MANAGER       ││
│  │     (Database Credentials)      ││    │  │     (Database Credentials)      ││
│  └─────────────────────────────────┘│    │  └─────────────────────────────────┘│
│                                     │    │                                     │
│  ┌─────────────────────────────────┐│    │  ┌─────────────────────────────────┐│
│  │            ECR                  ││    │  │            ECR                  ││
│  │    (Container Registry)         ││    │  │    (Container Registry)         ││
│  │   - lamp-apache:latest          ││    │  │   - lamp-apache:latest          ││
│  │   - lamp-apache:commit-sha      ││    │  │   - lamp-apache:commit-sha      ││
│  └─────────────────────────────────┘│    │  └─────────────────────────────────┘│
│                                     │    │                                     │
│  ┌─────────────────────────────────┐│    │  ┌─────────────────────────────────┐│
│  │        CLOUDWATCH LOGS          ││    │  │        CLOUDWATCH LOGS          ││
│  │      /ecs/lamp-visitor          ││    │  │      /ecs/lamp-visitor          ││
│  │     (3-day retention)           ││    │  │     (3-day retention)           ││
│  └─────────────────────────────────┘│    │  └─────────────────────────────────┘│
└─────────────────────────────────────┘    └─────────────────────────────────────┘
                  │                                   ▲
                  │                                   │
                  └─────────── RDS REPLICATION ──────┘
                           (Cross-Region Async)
```

## 🔧 **Component Details**

### **Network Layer**
- **VPC**: Isolated network environment
- **Public Subnets**: ALB, NAT Gateway, Internet Gateway
- **Private Subnets**: ECS tasks, RDS database
- **Security Groups**: Layered security (ALB → ECS → RDS)

### **Compute Layer**
- **ECS Fargate**: Serverless containers (512 CPU, 1GB RAM)
- **Auto Scaling**: 1-6 tasks based on CPU utilization
- **Health Checks**: ALB monitors `/health.php`

### **Data Layer**
- **RDS MySQL**: Managed database service
- **Secrets Manager**: Encrypted credential storage
- **Cross-Region Replication**: Async replication to DR

### **Load Balancing**
- **Application Load Balancer**: Layer 7 load balancing
- **Target Groups**: Health check configuration
- **Sticky Sessions**: Not required (stateless app)

## 📊 **Data Flow Diagram**

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   VISITOR   │───▶│     ALB     │───▶│ ECS FARGATE │───▶│ RDS MYSQL   │
│  (Browser)  │    │ (Port 80)   │    │ (Apache+PHP)│    │(Credentials │
└─────────────┘    └─────────────┘    └─────────────┘    │from Secrets)│
                                              │           └─────────────┘
                                              ▼
                                      ┌─────────────┐
                                      │ CLOUDWATCH  │
                                      │    LOGS     │
                                      └─────────────┘
```

## 🔐 **Security Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                        SECURITY LAYERS                         │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1: Network Security                                     │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ • VPC Isolation (11.0.0.0/16)                              ││
│  │ • Private Subnets for ECS and RDS                          ││
│  │ • NAT Gateway for outbound internet access                 ││
│  │ • Internet Gateway only for ALB                            ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│  Layer 2: Security Groups (Firewall Rules)                     │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ ALB Security Group:                                         ││
│  │ • Inbound: HTTP (80) from 0.0.0.0/0                        ││
│  │ • Outbound: All traffic                                     ││
│  │                                                             ││
│  │ ECS Security Group:                                         ││
│  │ • Inbound: HTTP (80) from ALB Security Group only          ││
│  │ • Outbound: All traffic                                     ││
│  │                                                             ││
│  │ RDS Security Group:                                         ││
│  │ • Inbound: MySQL (3306) from ECS Security Group only       ││
│  │ • Outbound: None                                            ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│  Layer 3: IAM Security                                          │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ ECS Execution Role:                                         ││
│  │ • AmazonECSTaskExecutionRolePolicy                          ││
│  │ • Custom Secrets Manager access policy                     ││
│  │                                                             ││
│  │ ECS Task Role:                                              ││
│  │ • Minimal permissions for application                      ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│  Layer 4: Data Security                                         │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ • AWS Secrets Manager for database credentials             ││
│  │ • Encryption at rest and in transit                        ││
│  │ • No hardcoded passwords in code                           ││
│  │ • Automatic secret rotation ready                          ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 **Auto Scaling Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                      AUTO SCALING FLOW                         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  CloudWatch Metrics Collection                                  │
│  • ECS Service CPU Utilization                                  │
│  • ECS Service Memory Utilization                               │
│  • ALB Request Count                                             │
│  • ALB Response Time                                             │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  Auto Scaling Policy Evaluation                                 │
│  • Target: 70% CPU Utilization                                  │
│  • Scale Out: CPU > 70% for 2 consecutive periods               │
│  • Scale In: CPU < 70% for 2 consecutive periods                │
│  • Cooldown: 300 seconds                                        │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  Scaling Action                                                  │
│  • Min Capacity: 1 task                                         │
│  • Max Capacity: 6 tasks                                        │
│  • Current: 2 tasks (normal operation)                          │
│  • Scale Out: +1 task at a time                                 │
│  • Scale In: -1 task at a time                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 🌐 **Multi-Region Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                    DISASTER RECOVERY FLOW                      │
└─────────────────────────────────────────────────────────────────┘

NORMAL OPERATION:
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   PRIMARY   │───▶│   ACTIVE    │───▶│   ACTIVE    │
│   REGION    │    │ APPLICATION │    │  DATABASE   │
│ (eu-west-1) │    │ (2 tasks)   │    │ (RDS MySQL) │
└─────────────┘    └─────────────┘    └─────┬───────┘
                                             │
                                             │ Async Replication
                                             ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│     DR      │    │   STANDBY   │    │   STANDBY   │
│   REGION    │    │ APPLICATION │    │  DATABASE   │
│(eu-central-1)│    │ (0 tasks)   │    │(Read Replica)│
└─────────────┘    └─────────────┘    └─────────────┘

DISASTER RECOVERY ACTIVATED:
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   PRIMARY   │    │   FAILED    │    │   FAILED    │
│   REGION    │ ✗  │ APPLICATION │ ✗  │  DATABASE   │ ✗
│ (eu-west-1) │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘

┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│     DR      │───▶│   ACTIVE    │───▶│   PROMOTED  │
│   REGION    │    │ APPLICATION │    │  DATABASE   │
│(eu-central-1)│    │ (2 tasks)   │    │ (Primary)   │
└─────────────┘    └─────────────┘    └─────────────┘
```