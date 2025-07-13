#!/bin/bash

set -e

echo "🔍 Troubleshooting 503 Service Unavailable Error"
echo "================================================"

# Get ALB DNS from Terraform
cd disaster-recovery
ALB_DNS=$(terraform output -raw primary_alb_dns 2>/dev/null || echo "")

if [ -z "$ALB_DNS" ]; then
    echo "❌ Could not get ALB DNS from Terraform outputs"
    exit 1
fi

echo "🌐 ALB DNS: $ALB_DNS"
echo ""

# Check ECS Service Status
echo "📊 ECS Service Status:"
aws ecs describe-services --cluster lamp-visitor-analytics --services lamp-visitor-analytics --query 'services[0].{runningCount:runningCount,desiredCount:desiredCount,status:status,taskDefinition:taskDefinition}'

echo ""
echo "📋 ECS Tasks:"
TASK_ARNS=$(aws ecs list-tasks --cluster lamp-visitor-analytics --service-name lamp-visitor-analytics --query 'taskArns' --output text)

if [ -n "$TASK_ARNS" ]; then
    aws ecs describe-tasks --cluster lamp-visitor-analytics --tasks $TASK_ARNS --query 'tasks[0].{lastStatus:lastStatus,healthStatus:healthStatus,containers:containers[0].{name:name,lastStatus:lastStatus,healthStatus:healthStatus}}'
else
    echo "❌ No tasks found"
fi

echo ""
echo "🎯 ALB Target Health:"
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names lamp-visitor-analytics --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")

if [ -n "$TARGET_GROUP_ARN" ] && [ "$TARGET_GROUP_ARN" != "None" ]; then
    aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
else
    echo "❌ Could not find target group"
fi

echo ""
echo "📝 Recent Container Logs:"
aws logs tail /ecs/lamp-visitor-analytics --since 10m || echo "❌ No logs available"

echo ""
echo "🧪 Testing Endpoints:"
echo "Health check:"
curl -v http://$ALB_DNS/health.php || echo "❌ Health check failed"

echo ""
echo "Main page:"
curl -I http://$ALB_DNS/ || echo "❌ Main page failed"

echo ""
echo "🔧 Common Solutions:"
echo "1. Wait 5-10 minutes for tasks to fully start"
echo "2. Check container logs for application errors"
echo "3. Verify database connectivity"
echo "4. Check security group rules"
echo "5. Verify health check endpoint returns 200"