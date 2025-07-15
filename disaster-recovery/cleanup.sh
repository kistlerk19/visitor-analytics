#!/bin/bash

echo "Cleaning up existing resources..."

# Clean up ECR repositories
aws ecr delete-repository --repository-name lamp-apache --force --region eu-west-1 2>/dev/null || true
aws ecr delete-repository --repository-name lamp-mysql --force --region eu-west-1 2>/dev/null || true
aws ecr delete-repository --repository-name lamp-apache --force --region eu-central-1 2>/dev/null || true
aws ecr delete-repository --repository-name lamp-mysql --force --region eu-central-1 2>/dev/null || true

# Clean up CloudWatch Log Groups
aws logs delete-log-group --log-group-name "/ecs/visitor-analytics" --region eu-west-1 2>/dev/null || true
aws logs delete-log-group --log-group-name "/ecs/visitor-analytics" --region eu-central-1 2>/dev/null || true

# Clean up IAM roles
aws iam detach-role-policy --role-name visitor-analytics-ecs-execution-role --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy 2>/dev/null || true
aws iam delete-role-policy --role-name visitor-analytics-ecs-execution-role --policy-name visitor-analytics-ecs-secrets-policy 2>/dev/null || true
aws iam delete-role --role-name visitor-analytics-ecs-execution-role 2>/dev/null || true
aws iam delete-role --role-name visitor-analytics-ecs-task-role 2>/dev/null || true

# Clean up Target Groups
TG_ARN=$(aws elbv2 describe-target-groups --names visitor-analytics-tg --query 'TargetGroups[0].TargetGroupArn' --output text --region eu-west-1 2>/dev/null)
if [ "$TG_ARN" != "None" ] && [ "$TG_ARN" != "" ]; then
    aws elbv2 delete-target-group --target-group-arn $TG_ARN --region eu-west-1 2>/dev/null || true
fi

TG_ARN_DR=$(aws elbv2 describe-target-groups --names visitor-analytics-tg --query 'TargetGroups[0].TargetGroupArn' --output text --region eu-central-1 2>/dev/null)
if [ "$TG_ARN_DR" != "None" ] && [ "$TG_ARN_DR" != "" ]; then
    aws elbv2 delete-target-group --target-group-arn $TG_ARN_DR --region eu-central-1 2>/dev/null || true
fi

# Clean up Secrets
aws secretsmanager delete-secret --secret-id visitor-analytics-db-credentials --force-delete-without-recovery --region eu-west-1 2>/dev/null || true
aws secretsmanager delete-secret --secret-id visitor-analytics-db-credentials --force-delete-without-recovery --region eu-central-1 2>/dev/null || true

echo "Cleanup completed. You can now run terraform apply."