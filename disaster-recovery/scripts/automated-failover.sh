#!/bin/bash

set -e

# Enhanced Disaster Recovery Failover Script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLUSTER_NAME="visitor-analytics"
DR_REGION="eu-central-1"
PRIMARY_REGION="eu-west-1"

echo "=== AUTOMATED DISASTER RECOVERY FAILOVER ==="
echo "Timestamp: $(date)"
echo "Primary Region: $PRIMARY_REGION"
echo "DR Region: $DR_REGION"

cd "$PROJECT_DIR"

# Function to check service health
check_health() {
    local endpoint=$1
    local region=$2
    echo "🔍 Checking health of $endpoint in $region..."
    
    if curl -f -s --max-time 10 "http://$endpoint/health-simple.php" > /dev/null; then
        echo "✅ $endpoint is healthy"
        return 0
    else
        echo "❌ $endpoint is unhealthy"
        return 1
    fi
}

# Function to wait for service stability
wait_for_service() {
    local cluster=$1
    local service=$2
    local region=$3
    local max_wait=600
    
    echo "⏳ Waiting for ECS service to stabilize in $region..."
    
    if aws ecs wait services-stable \
        --cluster "$cluster" \
        --services "$service" \
        --region "$region" \
        --cli-read-timeout $max_wait; then
        echo "✅ Service is stable"
        return 0
    else
        echo "❌ Service failed to stabilize within $max_wait seconds"
        return 1
    fi
}

# Step 1: Verify DR is enabled
echo "Step 1: Verifying DR configuration..."
DR_ENABLED=$(terraform output -raw dr_alb_dns 2>/dev/null || echo "null")
if [ "$DR_ENABLED" = "null" ] || [ -z "$DR_ENABLED" ]; then
    echo "❌ ERROR: DR is not enabled. Run with enable_dr=true first."
    exit 1
fi

PRIMARY_ALB=$(terraform output -raw primary_alb_dns)
DR_ALB=$(terraform output -raw dr_alb_dns)

echo "Primary ALB: $PRIMARY_ALB"
echo "DR ALB: $DR_ALB"

# Step 2: Check current health status
echo "Step 2: Checking current health status..."
PRIMARY_HEALTHY=false
DR_HEALTHY=false

if check_health "$PRIMARY_ALB" "$PRIMARY_REGION"; then
    PRIMARY_HEALTHY=true
fi

if check_health "$DR_ALB" "$DR_REGION"; then
    DR_HEALTHY=true
fi

echo "Primary Region Health: $PRIMARY_HEALTHY"
echo "DR Region Health: $DR_HEALTHY"

# Step 3: Determine if failover is needed
if [ "$PRIMARY_HEALTHY" = "true" ]; then
    echo "⚠️  Primary region is healthy. Are you sure you want to proceed with failover?"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Failover cancelled."
        exit 0
    fi
fi

# Step 4: Trigger Lambda-based failover
echo "Step 3: Triggering automated failover via Lambda..."
LAMBDA_FUNCTION=$(terraform output -raw lambda_dr_function)

aws lambda invoke \
    --function-name "$LAMBDA_FUNCTION" \
    --region "$PRIMARY_REGION" \
    --payload '{"trigger":"manual","reason":"disaster_recovery_test"}' \
    /tmp/lambda-response.json

echo "Lambda response:"
cat /tmp/lambda-response.json
echo

# Step 5: Monitor failover progress
echo "Step 4: Monitoring failover progress..."

# Wait for RDS replica promotion
echo "🔄 Waiting for RDS replica promotion..."
REPLICA_ID="${CLUSTER_NAME}-db-replica"
aws rds wait db-instance-available \
    --db-instance-identifier "$REPLICA_ID" \
    --region "$DR_REGION"

echo "✅ RDS replica promoted successfully"

# Wait for ECS service to scale up
if ! wait_for_service "$CLUSTER_NAME" "$CLUSTER_NAME" "$DR_REGION"; then
    echo "❌ ECS service failed to stabilize"
    exit 1
fi

# Step 6: Verify DR region health
echo "Step 5: Verifying DR region health..."
sleep 30  # Allow time for health checks

for i in {1..10}; do
    if check_health "$DR_ALB" "$DR_REGION"; then
        echo "✅ DR region is now healthy"
        break
    fi
    
    if [ $i -eq 10 ]; then
        echo "❌ DR region failed to become healthy after 10 attempts"
        exit 1
    fi
    
    echo "⏳ Attempt $i/10 - waiting 30 seconds..."
    sleep 30
done

# Step 7: Get final status
echo "Step 6: Getting final infrastructure status..."

DR_DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$REPLICA_ID" \
    --region "$DR_REGION" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

ECS_STATUS=$(aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services "$CLUSTER_NAME" \
    --region "$DR_REGION" \
    --query 'services[0].{running:runningCount,desired:desiredCount}')

echo "=== FAILOVER COMPLETE ==="
echo "✅ Disaster Recovery Activated Successfully"
echo ""
echo "📊 Final Status:"
echo "  DR Application URL: http://$DR_ALB"
echo "  DR Database Endpoint: $DR_DB_ENDPOINT"
echo "  ECS Service Status: $ECS_STATUS"
echo ""
echo "🔧 Next Steps:"
echo "  1. Update DNS records to point to DR ALB: $DR_ALB"
echo "  2. Update application configuration if needed"
echo "  3. Monitor application performance"
echo "  4. Plan recovery back to primary region when ready"
echo ""
echo "📋 Rollback Command:"
echo "  ./scripts/failback.sh"

# Step 8: Run basic application tests
echo "Step 7: Running basic application tests..."
echo "🧪 Testing main application..."
if curl -f -s "http://$DR_ALB/" > /dev/null; then
    echo "✅ Main application test passed"
else
    echo "⚠️  Main application test failed"
fi

echo "🧪 Testing API endpoint..."
if curl -f -s "http://$DR_ALB/api.php?action=stats" > /dev/null; then
    echo "✅ API test passed"
else
    echo "⚠️  API test failed"
fi

echo ""
echo "🎉 Automated failover completed successfully!"
echo "Timestamp: $(date)"