#!/bin/bash

echo "🚀 Local LAMP Stack Deployment"

# Check if required environment variables are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Missing required environment variables:"
    echo "   AWS_ACCESS_KEY_ID"
    echo "   AWS_SECRET_ACCESS_KEY" 
    echo "   AWS_ACCOUNT_ID"
    echo ""
    echo "Set them with:"
    echo "export AWS_ACCESS_KEY_ID=your-key"
    echo "export AWS_SECRET_ACCESS_KEY=your-secret"
    echo "export AWS_ACCOUNT_ID=your-account-id"
    exit 1
fi

cd disaster-recovery

# Create terraform.tfvars
cat > terraform.tfvars << EOF
primary_region = "eu-west-1"
dr_region = "eu-central-1"
environment = "prod"
notification_email = "admin@example.com"
aws_account_id = "$AWS_ACCOUNT_ID"
enable_dr = false
image_tag = "latest"
EOF

# Create S3 bucket for state
echo "📦 Creating S3 bucket for Terraform state..."
aws s3 mb s3://visitor-analytics-terraform-state-$AWS_ACCOUNT_ID --region eu-west-1 2>/dev/null || true

# Create backend configuration
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket = "visitor-analytics-terraform-state-$AWS_ACCOUNT_ID"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
EOF

# Initialize and deploy
echo "🔧 Initializing Terraform..."
terraform init

echo "🚀 Deploying infrastructure..."
terraform apply -auto-approve

echo "✅ Deployment completed!"
echo ""
echo "📊 Outputs:"
terraform output