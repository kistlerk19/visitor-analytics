#!/bin/bash

set -e

echo "🔄 Updating ECS Task Definition"
echo "==============================="

cd disaster-recovery

# Apply only the ECS changes
echo "📝 Applying Terraform changes..."
terraform plan -target=module.primary_ecs.aws_ecs_task_definition.app -out=tfplan-task
terraform apply -auto-approve tfplan-task

# Force new deployment
echo "🚀 Forcing new ECS deployment..."
aws ecs update-service --cluster visitor-analytics --service visitor-analytics --force-new-deployment

# Wait for deployment
echo "⏳ Waiting for deployment to complete..."
aws ecs wait services-stable --cluster visitor-analytics --services visitor-analytics

# Check service status
echo "📊 Service Status:"
aws ecs describe-services --cluster visitor-analytics --services visitor-analytics --query 'services[0].{runningCount:runningCount,desiredCount:desiredCount,status:status}'

# Get ALB DNS and test
ALB_DNS=$(terraform output -raw primary_alb_dns)
echo "🌐 Testing ALB: $ALB_DNS"

echo "⏳ Waiting for health checks..."
sleep 60

echo "🏥 Testing health endpoint..."
curl -f http://$ALB_DNS/health.php | jq '.' || {
    echo "❌ Still failing - check logs:"
    aws logs tail /ecs/visitor-analytics --since 5m
    exit 1
}

echo "✅ ECS task update completed successfully!"