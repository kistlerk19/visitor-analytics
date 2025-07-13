#!/bin/bash

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLUSTER_NAME="lamp-visitor-analytics"
DR_REGION="eu-central-1"

echo "=== DISASTER RECOVERY FAILOVER ==="
echo "Initiating failover to DR region: $DR_REGION"

cd "$PROJECT_DIR"

# Check if DR is enabled
DR_ENABLED=$(terraform output -raw dr_alb_dns 2>/dev/null || echo "null")
if [ "$DR_ENABLED" = "null" ]; then
    echo "ERROR: DR is not enabled. Run with enable_dr=true first."
    exit 1
fi

# Step 1: Promote RDS read replica
echo "Step 1: Promoting RDS read replica..."
REPLICA_ID="${CLUSTER_NAME}-db-replica"
aws rds promote-read-replica --db-instance-identifier $REPLICA_ID --region $DR_REGION

echo "Waiting for replica promotion to complete..."
aws rds wait db-instance-available --db-instance-identifier $REPLICA_ID --region $DR_REGION

# Step 2: Scale up ECS service in DR region
echo "Step 2: Scaling up ECS service in DR region..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $CLUSTER_NAME \
    --desired-count 2 \
    --region $DR_REGION

echo "Waiting for ECS service to stabilize..."
aws ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $CLUSTER_NAME \
    --region $DR_REGION

# Step 3: Get DR endpoints
DR_ALB_DNS=$(terraform output -raw dr_alb_dns)
DR_DB_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier $REPLICA_ID --region $DR_REGION --query 'DBInstances[0].Endpoint.Address' --output text)

echo "=== FAILOVER COMPLETE ==="
echo "DR Application URL: http://$DR_ALB_DNS"
echo "DR Database Endpoint: $DR_DB_ENDPOINT"
echo ""
echo "IMPORTANT: Update your DNS records to point to the DR ALB"
echo "IMPORTANT: Update application configuration to use the new DB endpoint"