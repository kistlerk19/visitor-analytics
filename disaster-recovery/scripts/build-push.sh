#!/bin/bash

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}
PRIMARY_REGION=${AWS_DEFAULT_REGION:-"eu-west-1"}
DR_REGION="eu-central-1"
IMAGE_TAG=${GITHUB_SHA:-"latest"}

echo "=== Building and Pushing Docker Images ==="
echo "Project Root: $PROJECT_ROOT"
echo "AWS Account: $AWS_ACCOUNT_ID"

cd "$PROJECT_ROOT"

# Login to ECR in primary region
echo "Logging into ECR (Primary: $PRIMARY_REGION)..."
aws ecr get-login-password --region $PRIMARY_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$PRIMARY_REGION.amazonaws.com

# Build Apache image with RDS support
echo "Building Apache image..."
docker build -f disaster-recovery/Dockerfile.apache-rds -t lamp-apache .
docker tag lamp-apache:latest $AWS_ACCOUNT_ID.dkr.ecr.$PRIMARY_REGION.amazonaws.com/lamp-apache:$IMAGE_TAG
docker tag lamp-apache:latest $AWS_ACCOUNT_ID.dkr.ecr.$PRIMARY_REGION.amazonaws.com/lamp-apache:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$PRIMARY_REGION.amazonaws.com/lamp-apache:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$PRIMARY_REGION.amazonaws.com/lamp-apache:latest

# Check if DR is enabled and replicate images
if [ "$1" = "--enable-dr" ]; then
    echo "Logging into ECR (DR: $DR_REGION)..."
    aws ecr get-login-password --region $DR_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$DR_REGION.amazonaws.com
    
    echo "Pushing to DR region..."
    docker tag lamp-apache:latest $AWS_ACCOUNT_ID.dkr.ecr.$DR_REGION.amazonaws.com/lamp-apache:$IMAGE_TAG
    docker tag lamp-apache:latest $AWS_ACCOUNT_ID.dkr.ecr.$DR_REGION.amazonaws.com/lamp-apache:latest
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$DR_REGION.amazonaws.com/lamp-apache:$IMAGE_TAG
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$DR_REGION.amazonaws.com/lamp-apache:latest
fi

echo "=== Image Build Complete ==="