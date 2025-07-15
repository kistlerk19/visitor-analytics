#!/bin/bash

echo "🗑️ Destroying Remote Infrastructure"

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Set AWS_ACCOUNT_ID environment variable"
    exit 1
fi

cd disaster-recovery

# Connect to remote state
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket = "visitor-analytics-terraform-state-$AWS_ACCOUNT_ID"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
EOF

# Create matching tfvars
cat > terraform.tfvars << EOF
primary_region = "eu-west-1"
dr_region = "eu-central-1"
environment = "prod"
notification_email = "admin@example.com"
aws_account_id = "$AWS_ACCOUNT_ID"
enable_dr = false
image_tag = "latest"
EOF

terraform init
terraform destroy -auto-approve

echo "✅ Infrastructure destroyed"