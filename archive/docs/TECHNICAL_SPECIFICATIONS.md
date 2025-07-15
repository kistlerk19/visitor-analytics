# Technical Specifications

## 🏗️ **Infrastructure Specifications**

### **Compute Resources**
```yaml
ECS Fargate Configuration:
  CPU: 512 units (0.5 vCPU)
  Memory: 1024 MB (1 GB)
  Network Mode: awsvpc
  Launch Type: FARGATE
  Platform Version: LATEST
  
Auto Scaling:
  Min Capacity: 1 task
  Max Capacity: 6 tasks
  Target CPU: 70%
  Scale Out Cooldown: 300 seconds
  Scale In Cooldown: 300 seconds
```

### **Database Specifications**
```yaml
RDS MySQL Configuration:
  Engine: MySQL 8.0
  Instance Class: db.t3.micro
  vCPU: 2
  Memory: 1 GB
  Storage: 20 GB GP2 SSD
  IOPS: Baseline 100, Burst 3000
  Multi-AZ: Disabled (cost optimization)
  Backup Retention: 0 days (cost optimization)
  Encryption: Disabled (cost optimization)
  
Read Replica (DR):
  Same specifications as primary
  Cross-region replication lag: <30 seconds
  Automatic failover: Manual promotion
```

### **Network Specifications**
```yaml
VPC Configuration:
  Primary Region CIDR: 11.0.0.0/16
  DR Region CIDR: 11.1.0.0/16
  
Subnets:
  Public Subnets:
    - 11.0.1.0/24 (AZ-a)
    - 11.0.2.0/24 (AZ-b)
  Private Subnets:
    - 11.0.3.0/24 (AZ-a)
    - 11.0.4.0/24 (AZ-b)
    
Load Balancer:
  Type: Application Load Balancer
  Scheme: Internet-facing
  IP Address Type: IPv4
  Health Check Path: /health.php
  Health Check Interval: 30 seconds
  Healthy Threshold: 2
  Unhealthy Threshold: 3
```

## 🔒 **Security Specifications**

### **Security Groups**
```yaml
ALB Security Group:
  Inbound Rules:
    - Port 80 (HTTP) from 0.0.0.0/0
    - Port 443 (HTTPS) from 0.0.0.0/0
  Outbound Rules:
    - All traffic to 0.0.0.0/0

ECS Security Group:
  Inbound Rules:
    - Port 80 from ALB Security Group
  Outbound Rules:
    - All traffic to 0.0.0.0/0

RDS Security Group:
  Inbound Rules:
    - Port 3306 from ECS Security Group
  Outbound Rules:
    - None
```

### **IAM Roles & Policies**
```yaml
ECS Execution Role:
  Policies:
    - AmazonECSTaskExecutionRolePolicy
    - Custom Secrets Manager Policy
  
ECS Task Role:
  Policies:
    - Minimal application permissions
    
Secrets Manager Policy:
  Actions:
    - secretsmanager:GetSecretValue
  Resources:
    - arn:aws:secretsmanager:*:*:secret:visitor-analytics-db-credentials*
```

### **Secrets Management**
```yaml
Database Credentials:
  Storage: AWS Secrets Manager
  Encryption: AES-256
  Rotation: Manual (ready for automatic)
  Cross-Region: Replicated to DR region
  
Secret Structure:
  {
    "username": "root",
    "password": "generated-16-char-password",
    "engine": "mysql",
    "host": "rds-endpoint",
    "port": 3306,
    "dbname": "visitor_analytics"
  }
```

## 🐳 **Container Specifications**

### **Docker Image**
```dockerfile
Base Image: php:8.2-apache
Size: ~400 MB
Architecture: linux/amd64

Installed Packages:
  - PHP Extensions: pdo, pdo_mysql, mysqli
  - System Packages: curl (for health checks)
  - Apache Modules: rewrite, headers

Application Structure:
  /var/www/html/
  ├── index.php          # Main visitor tracking page
  ├── health.php         # Health check endpoint
  ├── api.php           # REST API endpoint
  ├── debug.php         # Debug information
  ├── config/
  │   └── database.php  # Database connection
  ├── includes/
  │   ├── visitor_tracker.php
  │   ├── geolocation.php
  │   └── backup.php
  ├── css/
  │   └── style.css
  └── js/
      └── dashboard.js
```

### **Health Check Configuration**
```yaml
Container Health Check:
  Command: curl -f http://localhost/health.php
  Interval: 30 seconds
  Timeout: 3 seconds
  Start Period: 5 seconds
  Retries: 3

ALB Health Check:
  Path: /health.php
  Protocol: HTTP
  Port: 80
  Interval: 30 seconds
  Timeout: 5 seconds
  Healthy Threshold: 2
  Unhealthy Threshold: 3
  Success Codes: 200
```

## 📊 **Database Schema**

### **Visitor Analytics Table**
```sql
CREATE TABLE visitors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT,
    visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    country VARCHAR(100),
    city VARCHAR(100),
    browser VARCHAR(100),
    os VARCHAR(100),
    device VARCHAR(100),
    
    INDEX idx_visit_time (visit_time),
    INDEX idx_ip_address (ip_address)
);
```

### **Database Performance**
```yaml
Expected Load:
  Concurrent Connections: 10-50
  Queries per Second: 100-500
  Storage Growth: ~1MB per 10,000 visitors
  
Connection Pool:
  Max Connections: 151 (default for t3.micro)
  Connection Timeout: 30 seconds
  Query Timeout: 30 seconds
```

## 🌐 **API Specifications**

### **REST API Endpoints**
```yaml
GET /health.php:
  Description: Health check endpoint
  Response: JSON
  Example:
    {
      "status": "healthy",
      "database": "connected",
      "timestamp": "2024-01-01T12:00:00Z"
    }

GET /api.php?action=stats:
  Description: Visitor statistics
  Response: JSON
  Example:
    {
      "total_visitors": 1234,
      "today_visitors": 56,
      "unique_ips": 890,
      "top_countries": ["US", "UK", "DE"]
    }

GET /api.php?action=recent:
  Description: Recent visitors
  Response: JSON
  Example:
    {
      "visitors": [
        {
          "ip": "192.168.1.1",
          "country": "US",
          "browser": "Chrome",
          "time": "2024-01-01T12:00:00Z"
        }
      ]
    }
```

### **Response Formats**
```yaml
Success Response:
  HTTP Status: 200
  Content-Type: application/json
  Body: Valid JSON object

Error Response:
  HTTP Status: 500
  Content-Type: application/json
  Body:
    {
      "error": "Database connection failed",
      "timestamp": "2024-01-01T12:00:00Z"
    }
```

## 📈 **Performance Specifications**

### **Response Time Targets**
```yaml
Application Performance:
  Page Load Time: <2 seconds
  API Response Time: <500ms
  Health Check Response: <100ms
  Database Query Time: <50ms

Load Balancer Performance:
  Request Rate: 1000 requests/minute
  Connection Timeout: 60 seconds
  Response Timeout: 30 seconds
```

### **Scalability Limits**
```yaml
Current Configuration:
  Max Concurrent Users: ~500
  Max Requests/Second: ~100
  Max Database Connections: 151
  
Scaling Potential:
  ECS Tasks: 1-6 (can be increased)
  Database: Can upgrade to larger instance
  Load Balancer: Auto-scales
```

## 🔄 **Backup & Recovery Specifications**

### **Backup Strategy**
```yaml
Database Backup:
  Type: RDS Read Replica (DR region)
  Frequency: Continuous replication
  Retention: Until replica is deleted
  Recovery Point: <5 minutes

Container Images:
  Storage: ECR with lifecycle policy
  Retention: 5 latest images
  Backup: Cross-region replication (DR)

Configuration Backup:
  Type: Infrastructure as Code (Terraform)
  Storage: Git repository
  Versioning: Git commits
```

### **Recovery Specifications**
```yaml
Recovery Time Objective (RTO):
  Target: 10 minutes
  Components:
    - RDS Promotion: 2-3 minutes
    - ECS Scaling: 1-2 minutes
    - DNS Update: 5 minutes
    - Validation: 1 minute

Recovery Point Objective (RPO):
  Target: 5 minutes
  Actual: <30 seconds (read replica lag)
```

## 🔍 **Monitoring Specifications**

### **CloudWatch Metrics**
```yaml
ECS Metrics:
  - CPUUtilization
  - MemoryUtilization
  - RunningTaskCount
  - PendingTaskCount

ALB Metrics:
  - RequestCount
  - TargetResponseTime
  - HTTPCode_Target_2XX_Count
  - HTTPCode_Target_5XX_Count

RDS Metrics:
  - CPUUtilization
  - DatabaseConnections
  - ReadLatency
  - WriteLatency
  - ReplicaLag (for DR)
```

### **Log Specifications**
```yaml
Application Logs:
  Location: /ecs/visitor-analytics
  Retention: 3 days
  Format: Apache Combined Log Format
  
Database Logs:
  Error Log: Enabled
  Slow Query Log: Disabled (cost optimization)
  General Log: Disabled (cost optimization)

Load Balancer Logs:
  Access Logs: Disabled (cost optimization)
  Can be enabled for troubleshooting
```

## 💰 **Cost Specifications**

### **Monthly Cost Breakdown**
```yaml
Primary Region (eu-west-1):
  RDS t3.micro: $15.00
  ECS Fargate (2 tasks): $15.00
  ALB: $18.00
  NAT Gateway: $32.00
  Secrets Manager: $0.40
  CloudWatch Logs: $2.00
  ECR Storage: $1.00
  Data Transfer: $2.00
  Total: ~$85.40/month

DR Region (eu-central-1):
  RDS Read Replica: $15.00
  ECS Fargate (0 tasks): $0.00
  ALB: $18.00
  NAT Gateway: $32.00
  Secrets Manager: $0.40
  CloudWatch Logs: $1.00
  ECR Storage: $1.00
  Cross-Region Transfer: $3.00
  Total: ~$70.40/month

Grand Total: ~$155.80/month
```

### **Cost Optimization Features**
```yaml
Implemented Optimizations:
  ✅ Smallest RDS instance (t3.micro)
  ✅ No RDS backups
  ✅ Minimal storage (20GB)
  ✅ Short log retention (3 days)
  ✅ Pilot light DR (0 running tasks)
  ✅ ECR lifecycle policies
  ✅ No unnecessary features enabled

Potential Additional Savings:
  - Reserved Instances (20-40% savings)
  - Spot Instances for dev/test
  - S3 Intelligent Tiering
  - CloudWatch log compression
```

## 🔧 **Maintenance Specifications**

### **Update Procedures**
```yaml
Application Updates:
  Method: GitLab CI/CD pipeline
  Deployment: Rolling update (zero downtime)
  Rollback: Previous container image
  Testing: Automated health checks

Infrastructure Updates:
  Method: Terraform apply
  Testing: terraform plan review
  Rollback: terraform state rollback
  Approval: Manual approval for production

Security Updates:
  Container Base Image: Monthly
  RDS Engine: Quarterly (maintenance window)
  AWS Services: Automatic
```

### **Monitoring & Alerting**
```yaml
Alert Thresholds:
  ECS CPU > 80% for 5 minutes
  RDS CPU > 80% for 5 minutes
  ALB 5xx errors > 5% for 2 minutes
  Health check failures > 50% for 3 minutes
  Read replica lag > 60 seconds

Notification Methods:
  - Email alerts
  - CloudWatch dashboards
  - AWS SNS (can be configured)
```