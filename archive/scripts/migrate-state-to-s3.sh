#!/bin/bash

set -e

echo "📦 Migrating Terraform state to S3 backend"
echo "=========================================="

cd disaster-recovery

# Check if local state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ No local terraform.tfstate found"
    echo "💡 If you have existing infrastructure, run terraform import commands"
    exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="visitor-analytics-terraform-state-$AWS_ACCOUNT_ID"

echo "🪣 Creating S3 bucket: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region eu-west-1 2>/dev/null || echo "Bucket already exists"
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

echo "📝 Creating backend configuration..."
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket = "$BUCKET_NAME"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
EOF

echo "🔄 Migrating state to S3..."
terraform init -migrate-state -force-copy

echo "✅ State migration completed!"
echo "🗑️  You can now delete local state files:"
echo "   rm terraform.tfstate*"