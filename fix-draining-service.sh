#!/bin/bash

set -e

echo "🔧 Fixing ECS Service Draining Issue"
echo "===================================="

# Check current service status
echo "📊 Current ECS service status:"
aws ecs describe-services --cluster lamp-visitor-analytics --services lamp-visitor-analytics --query 'services[0].{status:status,runningCount:runningCount,desiredCount:desiredCount}' 2>/dev/null || echo "No service found"

# Scale down to 0 if service exists
echo "⬇️  Scaling service to 0..."
aws ecs update-service --cluster lamp-visitor-analytics --service lamp-visitor-analytics --desired-count 0 2>/dev/null || echo "Service not found or already scaled"

# Wait for service to stabilize
echo "⏳ Waiting for service to drain (this may take up to 10 minutes)..."
aws ecs wait services-stable --cluster lamp-visitor-analytics --services lamp-visitor-analytics --cli-read-timeout 600 2>/dev/null || echo "Service not found or timeout"

# Delete the service
echo "🗑️  Deleting service..."
aws ecs delete-service --cluster lamp-visitor-analytics --service lamp-visitor-analytics 2>/dev/null || echo "Service not found"

# Wait a bit more
echo "⏳ Waiting for cleanup to complete..."
sleep 30

# Check if service is gone
echo "✅ Checking service status:"
aws ecs describe-services --cluster lamp-visitor-analytics --services lamp-visitor-analytics 2>/dev/null || echo "✅ Service successfully removed"

echo ""
echo "🎉 ECS service cleanup completed!"
echo "💡 You can now re-run your deployment"