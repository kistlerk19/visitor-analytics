#!/bin/bash

set -e

# Complete Deployment Script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Complete LAMP Stack Deployment ==="

cd "$PROJECT_DIR"

# Step 1: Deploy Infrastructure
echo "Step 1: Deploying infrastructure..."
./scripts/deploy.sh

# Step 2: Build and Push Images
echo "Step 2: Building and pushing Docker images..."
./scripts/build-push.sh

# Step 3: Initialize Database
echo "Step 3: Initializing database..."
./scripts/init-database.sh

# Step 4: Verify Deployment
echo "Step 4: Verifying deployment..."
ALB_DNS=$(terraform output -raw primary_alb_dns)
DB_ENDPOINT=$(terraform output -raw primary_db_endpoint)

echo "=== Deployment Complete ==="
echo "Application URL: http://$ALB_DNS"
echo "Database Endpoint: $DB_ENDPOINT"
echo ""
echo "Testing endpoints:"
echo "- Health: http://$ALB_DNS/health.php"
echo "- API: http://$ALB_DNS/api.php?action=stats"
echo "- Debug: http://$ALB_DNS/debug.php"
echo ""
echo "Next steps:"
echo "1. Test the application in your browser"
echo "2. Run './scripts/enable-dr.sh' to enable disaster recovery"
echo "3. Set up monitoring and alerts"