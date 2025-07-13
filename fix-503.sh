#!/bin/bash

set -e

echo "🔧 Fixing 503 Service Unavailable Issues"
echo "========================================"

# Force ECS service update
echo "🔄 Forcing ECS service update..."
aws ecs update-service --cluster lamp-visitor-analytics --service lamp-visitor-analytics --force-new-deployment

# Wait for deployment
echo "⏳ Waiting for new deployment..."
aws ecs wait services-stable --cluster lamp-visitor-analytics --services lamp-visitor-analytics

# Check service status
echo "📊 Service Status:"
aws ecs describe-services --cluster lamp-visitor-analytics --services lamp-visitor-analytics --query 'services[0].{runningCount:runningCount,desiredCount:desiredCount,status:status}'

# Get ALB DNS and test
cd disaster-recovery
ALB_DNS=$(terraform output -raw primary_alb_dns)
echo "🌐 Testing ALB: $ALB_DNS"

# Wait a bit more for health checks
echo "⏳ Waiting for health checks..."
sleep 60

# Test health endpoint
echo "🏥 Testing health endpoint..."
curl -f http://$ALB_DNS/health.php | jq '.' || {
    echo "❌ Still failing - run ./troubleshoot-503.sh for detailed diagnosis"
    exit 1
}

echo "✅ Service is now healthy!"