#!/bin/bash

set -e

# Failback Script - Return from DR to Primary Region
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLUSTER_NAME="lamp-visitor-analytics"
DR_REGION="eu-central-1"
PRIMARY_REGION="eu-west-1"

echo "=== DISASTER RECOVERY FAILBACK ==="
echo "Returning from DR region to Primary region"
echo "Timestamp: $(date)"

cd "$PROJECT_DIR"

# Step 1: Verify current state
echo "Step 1: Verifying current state..."
PRIMARY_ALB=$(terraform output -raw primary_alb_dns)
DR_ALB=$(terraform output -raw dr_alb_dns)

echo "Primary ALB: $PRIMARY_ALB"
echo "DR ALB: $DR_ALB"

# Step 2: Check primary region health
echo "Step 2: Checking primary region health..."
if curl -f -s --max-time 10 "http://$PRIMARY_ALB/health-simple.php" > /dev/null; then
    echo "✅ Primary region is healthy"
else
    echo "❌ Primary region is still unhealthy. Cannot failback."
    exit 1
fi

# Step 3: Scale up primary region
echo "Step 3: Scaling up primary region ECS service..."
aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$CLUSTER_NAME" \
    --desired-count 2 \
    --region "$PRIMARY_REGION"

echo "⏳ Waiting for primary region service to stabilize..."
aws ecs wait services-stable \
    --cluster "$CLUSTER_NAME" \
    --services "$CLUSTER_NAME" \
    --region "$PRIMARY_REGION" \
    --cli-read-timeout 600

# Step 4: Verify primary region health again
echo "Step 4: Verifying primary region health after scale-up..."
sleep 30

for i in {1..5}; do
    if curl -f -s --max-time 10 "http://$PRIMARY_ALB/health-simple.php" > /dev/null; then
        echo "✅ Primary region is healthy"
        break
    fi
    
    if [ $i -eq 5 ]; then
        echo "❌ Primary region failed health check after scale-up"
        exit 1
    fi
    
    echo "⏳ Attempt $i/5 - waiting 30 seconds..."
    sleep 30
done

# Step 5: Scale down DR region
echo "Step 5: Scaling down DR region ECS service..."
aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "$CLUSTER_NAME" \
    --desired-count 0 \
    --region "$DR_REGION"

echo "⏳ Waiting for DR region service to scale down..."
aws ecs wait services-stable \
    --cluster "$CLUSTER_NAME" \
    --services "$CLUSTER_NAME" \
    --region "$DR_REGION" \
    --cli-read-timeout 300

echo "=== FAILBACK COMPLETE ==="
echo "✅ Successfully failed back to primary region"
echo ""
echo "📊 Final Status:"
echo "  Primary Application URL: http://$PRIMARY_ALB"
echo "  DR Region: Scaled to 0 (pilot light mode)"
echo ""
echo "🔧 Next Steps:"
echo "  1. Update DNS records to point back to primary ALB: $PRIMARY_ALB"
echo "  2. Monitor primary region performance"
echo "  3. Ensure DR region remains in pilot light mode"
echo ""
echo "🎉 Failback completed successfully!"
echo "Timestamp: $(date)"