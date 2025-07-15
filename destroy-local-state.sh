#!/bin/bash

echo "🗑️ Destroying with Local State File"

cd disaster-recovery

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

# Use local state (no backend)
rm -f backend.tf

terraform init
terraform destroy -auto-approve

echo "✅ Infrastructure destroyed using local state"