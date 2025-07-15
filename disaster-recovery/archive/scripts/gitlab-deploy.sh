#!/bin/bash

set -e

# GitLab CI Integration Script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== GitLab CI Terraform Deployment ==="

cd "$PROJECT_DIR"

# Create terraform.tfvars for GitLab CI
cat > terraform.tfvars << EOF
primary_region     = "${AWS_DEFAULT_REGION:-eu-west-1}"
dr_region         = "eu-central-1"
environment       = "prod"
notification_email = "${NOTIFICATION_EMAIL}"
aws_account_id    = "${AWS_ACCOUNT_ID}"
enable_dr         = ${ENABLE_DR:-false}
EOF

# Initialize and apply Terraform
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# Output important values for GitLab CI
echo "=== Terraform Outputs ==="
echo "Primary ALB DNS: $(terraform output -raw primary_alb_dns)"
echo "Primary DB Endpoint: $(terraform output -raw primary_db_endpoint)"
echo "Apache ECR Repository: $(terraform output -raw primary_ecr_apache)"

# Export task definition for ECS updates
terraform output -raw ecs_task_definition_json > task-definition.json
echo "Task definition exported to task-definition.json"

echo "=== Deployment Complete ==="