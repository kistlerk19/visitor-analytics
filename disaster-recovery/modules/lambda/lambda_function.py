import json
import boto3
import os

def handler(event, context):
    """
    Lambda function to automate disaster recovery failover
    """
    cluster_name = os.environ['CLUSTER_NAME']
    dr_region = os.environ['DR_REGION']
    primary_region = os.environ['PRIMARY_REGION']
    
    # Initialize AWS clients
    ecs_client = boto3.client('ecs', region_name=dr_region)
    rds_client = boto3.client('rds', region_name=dr_region)
    sns_client = boto3.client('sns', region_name=primary_region)
    
    try:
        # Step 1: Promote RDS read replica
        replica_id = f"{cluster_name}-db-replica"
        print(f"Promoting RDS replica: {replica_id}")
        
        rds_client.promote_read_replica(
            DBInstanceIdentifier=replica_id
        )
        
        # Step 2: Scale up ECS service
        print(f"Scaling up ECS service in DR region")
        
        ecs_client.update_service(
            cluster=cluster_name,
            service=cluster_name,
            desiredCount=2
        )
        
        # Step 3: Send notification
        message = f"""
        Disaster Recovery Activated Successfully
        
        Cluster: {cluster_name}
        DR Region: {dr_region}
        
        Actions Completed:
        - RDS replica promoted to primary
        - ECS service scaled to 2 tasks
        
        Please update DNS records to point to DR region.
        """
        
        # Get SNS topic ARN from environment or construct it
        account_id = context.invoked_function_arn.split(':')[4]
        topic_arn = f"arn:aws:sns:{primary_region}:{account_id}:{cluster_name}-dr-alerts"
        
        sns_client.publish(
            TopicArn=topic_arn,
            Subject="DR Activation Complete",
            Message=message
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'DR activation completed successfully',
                'cluster': cluster_name,
                'region': dr_region
            })
        }
        
    except Exception as e:
        error_message = f"DR activation failed: {str(e)}"
        print(error_message)
        
        # Send error notification
        try:
            account_id = context.invoked_function_arn.split(':')[4]
            topic_arn = f"arn:aws:sns:{primary_region}:{account_id}:{cluster_name}-dr-alerts"
            
            sns_client.publish(
                TopicArn=topic_arn,
                Subject="DR Activation Failed",
                Message=f"DR activation failed for {cluster_name}: {str(e)}"
            )
        except:
            pass
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_message
            })
        }