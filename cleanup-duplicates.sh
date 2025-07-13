#!/bin/bash

set -e

echo "🧹 Cleaning up duplicate infrastructure"
echo "======================================"

echo "⚠️  This will delete ALL lamp-visitor-analytics resources"
read -p "Are you sure? Type 'DELETE ALL' to continue: " confirm

if [ "$confirm" != "DELETE ALL" ]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo "🗑️  Deleting ECS resources..."
# Delete all ECS services
aws ecs list-services --cluster lamp-visitor-analytics --query 'serviceArns[]' --output text | xargs -n1 -I {} aws ecs update-service --cluster lamp-visitor-analytics --service {} --desired-count 0 2>/dev/null || true
sleep 30
aws ecs list-services --cluster lamp-visitor-analytics --query 'serviceArns[]' --output text | xargs -n1 -I {} aws ecs delete-service --cluster lamp-visitor-analytics --service {} 2>/dev/null || true

# Delete ECS clusters
aws ecs list-clusters --query 'clusterArns[]' --output text | grep lamp-visitor-analytics | xargs -n1 -I {} aws ecs delete-cluster --cluster {} 2>/dev/null || true

echo "🗑️  Deleting RDS instances..."
# Delete RDS instances
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `lamp-visitor-analytics`)].DBInstanceIdentifier' --output text | xargs -n1 -I {} aws rds delete-db-instance --db-instance-identifier {} --skip-final-snapshot 2>/dev/null || true

# Delete RDS replicas in DR region
aws rds describe-db-instances --region eu-central-1 --query 'DBInstances[?contains(DBInstanceIdentifier, `lamp-visitor-analytics`)].DBInstanceIdentifier' --output text | xargs -n1 -I {} aws rds delete-db-instance --region eu-central-1 --db-instance-identifier {} --skip-final-snapshot 2>/dev/null || true

echo "🗑️  Deleting Load Balancers..."
# Delete ALBs
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `lamp`) || contains(LoadBalancerName, `alb`)].LoadBalancerArn' --output text | xargs -n1 -I {} aws elbv2 delete-load-balancer --load-balancer-arn {} 2>/dev/null || true

echo "🗑️  Waiting for resources to delete..."
sleep 60

echo "🗑️  Deleting VPCs and networking..."
# Delete VPCs (this will cascade delete subnets, route tables, etc.)
aws ec2 describe-vpcs --filters "Name=is-default,Values=false" --query 'Vpcs[].VpcId' --output text | while read vpc; do
    if [ -n "$vpc" ]; then
        echo "Deleting VPC: $vpc"
        
        # Delete NAT Gateways first
        aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc" --query 'NatGateways[].NatGatewayId' --output text | xargs -n1 -I {} aws ec2 delete-nat-gateway --nat-gateway-id {} 2>/dev/null || true
        
        sleep 30
        
        # Detach and delete internet gateways
        aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[].InternetGatewayId' --output text | while read igw; do
            if [ -n "$igw" ]; then
                aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc 2>/dev/null || true
                aws ec2 delete-internet-gateway --internet-gateway-id $igw 2>/dev/null || true
            fi
        done
        
        # Delete subnets
        aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --query 'Subnets[].SubnetId' --output text | xargs -n1 -I {} aws ec2 delete-subnet --subnet-id {} 2>/dev/null || true
        
        # Delete VPC
        aws ec2 delete-vpc --vpc-id $vpc 2>/dev/null || true
    fi
done

echo "🗑️  Releasing Elastic IPs..."
# Release unassociated Elastic IPs
aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].AllocationId' --output text | xargs -n1 -I {} aws ec2 release-address --allocation-id {} 2>/dev/null || true

echo "🗑️  Deleting ECR repositories..."
# Delete ECR repositories
aws ecr describe-repositories --query 'repositories[?contains(repositoryName, `lamp`)].repositoryName' --output text | xargs -n1 -I {} aws ecr delete-repository --repository-name {} --force 2>/dev/null || true

echo "🗑️  Deleting Secrets..."
# Delete secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `lamp-visitor-analytics`)].Name' --output text | xargs -n1 -I {} aws secretsmanager delete-secret --secret-id {} --force-delete-without-recovery 2>/dev/null || true

echo "🗑️  Deleting CloudWatch logs..."
# Delete log groups
aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, `lamp`) || contains(logGroupName, `ecs`)].logGroupName' --output text | xargs -n1 -I {} aws logs delete-log-group --log-group-name {} 2>/dev/null || true

echo "✅ Cleanup completed!"
echo "💡 Now you can run a fresh deployment"