#!/bin/bash

set -e

# DR Testing Script - Non-destructive DR testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLUSTER_NAME="lamp-visitor-analytics"
DR_REGION="eu-central-1"
PRIMARY_REGION="eu-west-1"

echo "=== DISASTER RECOVERY TESTING ==="
echo "Non-destructive DR infrastructure testing"
echo "Timestamp: $(date)"

cd "$PROJECT_DIR"

# Function to test endpoint
test_endpoint() {
    local endpoint=$1
    local name=$2
    local region=$3
    
    echo "🧪 Testing $name ($endpoint) in $region..."
    
    # Health check
    if curl -f -s --max-time 10 "http://$endpoint/health-simple.php" > /dev/null; then
        echo "  ✅ Health check: PASS"
    else
        echo "  ❌ Health check: FAIL"
        return 1
    fi
    
    # Main application
    if curl -f -s --max-time 10 "http://$endpoint/" > /dev/null; then
        echo "  ✅ Main application: PASS"
    else
        echo "  ❌ Main application: FAIL"
        return 1
    fi
    
    # API endpoint
    if curl -f -s --max-time 10 "http://$endpoint/api.php?action=stats" > /dev/null; then
        echo "  ✅ API endpoint: PASS"
    else
        echo "  ❌ API endpoint: FAIL"
        return 1
    fi
    
    return 0
}

# Step 1: Verify DR is enabled
echo "Step 1: Verifying DR configuration..."
DR_ENABLED=$(terraform output -raw dr_alb_dns 2>/dev/null || echo "null")
if [ "$DR_ENABLED" = "null" ] || [ -z "$DR_ENABLED" ]; then
    echo "❌ ERROR: DR is not enabled. Enable DR first."
    exit 1
fi

PRIMARY_ALB=$(terraform output -raw primary_alb_dns)
DR_ALB=$(terraform output -raw dr_alb_dns)

echo "✅ DR is enabled"
echo "Primary ALB: $PRIMARY_ALB"
echo "DR ALB: $DR_ALB"

# Step 2: Test primary region
echo ""
echo "Step 2: Testing primary region..."
PRIMARY_HEALTHY=false
if test_endpoint "$PRIMARY_ALB" "Primary Region" "$PRIMARY_REGION"; then
    PRIMARY_HEALTHY=true
    echo "✅ Primary region: ALL TESTS PASSED"
else
    echo "❌ Primary region: TESTS FAILED"
fi

# Step 3: Temporarily scale up DR for testing
echo ""
echo "Step 3: Temporarily scaling up DR region for testing..."
ORIGINAL_DR_COUNT=$(aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services "$CLUSTER_NAME" \
    --region "$DR_REGION" \
    --query 'services[0].desiredCount' \
    --output text)

echo "Current DR desired count: $ORIGINAL_DR_COUNT"

if [ "$ORIGINAL_DR_COUNT" -eq 0 ]; then
    echo "🔄 Scaling DR region to 1 task for testing..."
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$CLUSTER_NAME" \
        --desired-count 1 \
        --region "$DR_REGION" > /dev/null
    
    echo "⏳ Waiting for DR service to stabilize..."
    aws ecs wait services-stable \
        --cluster "$CLUSTER_NAME" \
        --services "$CLUSTER_NAME" \
        --region "$DR_REGION" \
        --cli-read-timeout 300
    
    SCALED_UP=true
else
    SCALED_UP=false
fi

# Step 4: Test DR region
echo ""
echo "Step 4: Testing DR region..."
sleep 30  # Allow time for health checks

DR_HEALTHY=false
for i in {1..5}; do
    if test_endpoint "$DR_ALB" "DR Region" "$DR_REGION"; then
        DR_HEALTHY=true
        echo "✅ DR region: ALL TESTS PASSED"
        break
    fi
    
    if [ $i -eq 5 ]; then
        echo "❌ DR region: TESTS FAILED after 5 attempts"
    else
        echo "⏳ Attempt $i/5 - waiting 30 seconds..."
        sleep 30
    fi
done

# Step 5: Test database replication
echo ""
echo "Step 5: Testing database replication..."
REPLICA_ID="${CLUSTER_NAME}-db-replica"

REPLICA_STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier "$REPLICA_ID" \
    --region "$DR_REGION" \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text 2>/dev/null || echo "not-found")

if [ "$REPLICA_STATUS" = "available" ]; then
    echo "✅ RDS read replica: HEALTHY"
    
    # Check replication lag
    REPLICA_LAG=$(aws rds describe-db-instances \
        --db-instance-identifier "$REPLICA_ID" \
        --region "$DR_REGION" \
        --query 'DBInstances[0].StatusInfos[?StatusType==`read replication`].Message' \
        --output text 2>/dev/null || echo "unknown")
    
    echo "  Replication status: $REPLICA_LAG"
else
    echo "❌ RDS read replica: $REPLICA_STATUS"
fi

# Step 6: Test Lambda functions
echo ""
echo "Step 6: Testing Lambda functions..."
LAMBDA_DR_FUNCTION=$(terraform output -raw lambda_dr_function)
LAMBDA_HEALTH_FUNCTION=$(terraform output -raw lambda_health_function)

# Test health monitor function
echo "🧪 Testing health monitor Lambda..."
aws lambda invoke \
    --function-name "$LAMBDA_HEALTH_FUNCTION" \
    --region "$PRIMARY_REGION" \
    --payload '{"test":true}' \
    /tmp/health-test.json > /dev/null

if [ $? -eq 0 ]; then
    echo "✅ Health monitor Lambda: PASS"
    echo "  Response: $(cat /tmp/health-test.json)"
else
    echo "❌ Health monitor Lambda: FAIL"
fi

# Step 7: Test S3 replication
echo ""
echo "Step 7: Testing S3 cross-region replication..."
S3_BUCKET=$(terraform output -raw s3_assets_bucket)
DR_S3_BUCKET=$(terraform output -raw dr_s3_assets_bucket)

if [ "$DR_S3_BUCKET" != "null" ] && [ -n "$DR_S3_BUCKET" ]; then
    # Create test file
    echo "test-$(date +%s)" > /tmp/dr-test.txt
    
    # Upload to primary bucket
    aws s3 cp /tmp/dr-test.txt "s3://$S3_BUCKET/dr-test.txt" --region "$PRIMARY_REGION"
    
    # Wait and check DR bucket
    sleep 10
    if aws s3 ls "s3://$DR_S3_BUCKET/dr-test.txt" --region "$DR_REGION" > /dev/null 2>&1; then
        echo "✅ S3 cross-region replication: PASS"
        
        # Cleanup
        aws s3 rm "s3://$S3_BUCKET/dr-test.txt" --region "$PRIMARY_REGION" > /dev/null
        aws s3 rm "s3://$DR_S3_BUCKET/dr-test.txt" --region "$DR_REGION" > /dev/null
    else
        echo "❌ S3 cross-region replication: FAIL"
    fi
else
    echo "⚠️  S3 cross-region replication: NOT CONFIGURED"
fi

# Step 8: Scale DR back down if we scaled it up
if [ "$SCALED_UP" = "true" ]; then
    echo ""
    echo "Step 8: Scaling DR region back to pilot light mode..."
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$CLUSTER_NAME" \
        --desired-count 0 \
        --region "$DR_REGION" > /dev/null
    
    echo "⏳ Waiting for DR service to scale down..."
    aws ecs wait services-stable \
        --cluster "$CLUSTER_NAME" \
        --services "$CLUSTER_NAME" \
        --region "$DR_REGION" \
        --cli-read-timeout 300
    
    echo "✅ DR region scaled back to pilot light mode"
fi

# Step 9: Generate test report
echo ""
echo "=== DR TEST REPORT ==="
echo "Timestamp: $(date)"
echo ""
echo "📊 Test Results:"
echo "  Primary Region Health: $([ "$PRIMARY_HEALTHY" = "true" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "  DR Region Health: $([ "$DR_HEALTHY" = "true" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo "  Database Replication: $([ "$REPLICA_STATUS" = "available" ] && echo "✅ PASS" || echo "❌ FAIL")"
echo ""
echo "🏗️  Infrastructure Status:"
echo "  Primary ALB: $PRIMARY_ALB"
echo "  DR ALB: $DR_ALB"
echo "  RDS Replica: $REPLICA_STATUS"
echo "  S3 Primary: $S3_BUCKET"
echo "  S3 DR: $DR_S3_BUCKET"
echo ""

if [ "$PRIMARY_HEALTHY" = "true" ] && [ "$DR_HEALTHY" = "true" ] && [ "$REPLICA_STATUS" = "available" ]; then
    echo "🎉 DR TEST PASSED - Infrastructure is ready for disaster recovery"
    exit 0
else
    echo "⚠️  DR TEST FAILED - Some components need attention"
    exit 1
fi