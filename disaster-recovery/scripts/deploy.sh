#!/bin/bash

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=== LAMP Stack Disaster Recovery Deployment ==="
echo "Project Directory: $PROJECT_DIR"
echo "AWS Account: $AWS_ACCOUNT_ID"

# Check if terraform.tfvars exists
if [ ! -f "$PROJECT_DIR/terraform.tfvars" ]; then
    echo "Creating terraform.tfvars from example..."
    cp "$PROJECT_DIR/terraform.tfvars.example" "$PROJECT_DIR/terraform.tfvars"
    sed -i "s/123456789012/$AWS_ACCOUNT_ID/g" "$PROJECT_DIR/terraform.tfvars"
    echo "Please edit terraform.tfvars with your values before continuing."
    exit 1
fi

cd "$PROJECT_DIR"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan deployment
echo "Planning deployment..."
terraform plan -out=tfplan

# Apply deployment
echo "Applying deployment..."
terraform apply tfplan

# Get outputs
echo "=== Deployment Complete ==="
echo "Primary ALB DNS: $(terraform output -raw primary_alb_dns)"
echo "Primary DB Endpoint: $(terraform output -raw primary_db_endpoint)"

if [ "$(terraform output -raw dr_alb_dns)" != "null" ]; then
    echo "DR ALB DNS: $(terraform output -raw dr_alb_dns)"
    echo "DR DB Endpoint: $(terraform output -raw dr_db_endpoint)"
fi

echo "=== Next Steps ==="
echo "1. Build and push Docker images to ECR"
echo "2. Update ECS service to use new images"
echo "3. Test application health"