#!/bin/bash

set -e

echo "🔍 Comprehensive 503 Error Diagnosis"
echo "===================================="

cd disaster-recovery

# Get ALB DNS
ALB_DNS=$(terraform output -raw primary_alb_dns 2>/dev/null || echo "")
if [ -z "$ALB_DNS" ]; then
    echo "❌ Could not get ALB DNS"
    exit 1
fi

echo "🌐 ALB DNS: $ALB_DNS"
echo ""

# 1. Check ECS Service
echo "📊 ECS Service Status:"
aws ecs describe-services --cluster visitor-analytics --services visitor-analytics --query 'services[0].{status:status,runningCount:runningCount,desiredCount:desiredCount,pendingCount:pendingCount}'

# 2. Check ECS Tasks
echo ""
echo "📋 ECS Tasks:"
TASK_ARNS=$(aws ecs list-tasks --cluster visitor-analytics --service-name visitor-analytics --query 'taskArns[]' --output text)

if [ -n "$TASK_ARNS" ]; then
    for task in $TASK_ARNS; do
        echo "Task: $task"
        aws ecs describe-tasks --cluster visitor-analytics --tasks $task --query 'tasks[0].{lastStatus:lastStatus,healthStatus:healthStatus,stopCode:stopCode,stoppedReason:stoppedReason}'
        
        # Check container status
        echo "Container Status:"
        aws ecs describe-tasks --cluster visitor-analytics --tasks $task --query 'tasks[0].containers[0].{name:name,lastStatus:lastStatus,healthStatus:healthStatus,reason:reason}'
        echo ""
    done
else
    echo "❌ No tasks found"
fi

# 3. Check Target Group Health
echo "🎯 ALB Target Health:"
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names visitor-analytics --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)

if [ -n "$TARGET_GROUP_ARN" ] && [ "$TARGET_GROUP_ARN" != "None" ]; then
    aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
else
    echo "❌ Target group not found"
fi

# 4. Check Container Logs
echo ""
echo "📝 Recent Container Logs (last 20 lines):"
aws logs tail /ecs/visitor-analytics --since 5m --max-items 20 2>/dev/null || echo "❌ No logs available"

# 5. Check Database Connectivity
echo ""
echo "🗄️ Database Status:"
aws rds describe-db-instances --db-instance-identifier visitor-analytics-db --query 'DBInstances[0].{status:DBInstanceStatus,endpoint:Endpoint.Address}' 2>/dev/null || echo "❌ Database not found"

# 6. Test Direct Health Check
echo ""
echo "🏥 Testing Health Endpoint:"
curl -v -m 10 http://$ALB_DNS/health.php 2>&1 || echo "❌ Health check failed"

# 7. Check Security Groups
echo ""
echo "🔒 Security Group Rules:"
echo "ALB Security Group:"
ALB_SG=$(aws elbv2 describe-load-balancers --names alb-* --query 'LoadBalancers[0].SecurityGroups[0]' --output text 2>/dev/null)
if [ -n "$ALB_SG" ]; then
    aws ec2 describe-security-groups --group-ids $ALB_SG --query 'SecurityGroups[0].IpPermissions[?FromPort==`80`]'
fi

echo ""
echo "🔧 Recommended Actions:"
echo "1. Check container logs for application errors"
echo "2. Verify database connection from ECS tasks"
echo "3. Ensure health check endpoint returns 200"
echo "4. Check if tasks are starting successfully"
echo "5. Verify security group allows traffic on port 80"