import json
import boto3
import urllib3
import os

def handler(event, context):
    """
    Lambda function to monitor application health and trigger DR if needed
    """
    primary_alb_dns = os.environ.get('PRIMARY_ALB_DNS')
    dr_alb_dns = os.environ.get('DR_ALB_DNS')
    sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
    
    http = urllib3.PoolManager()
    sns_client = boto3.client('sns')
    
    # Health check primary region
    primary_healthy = check_health(http, primary_alb_dns)
    
    if not primary_healthy:
        print(f"Primary region unhealthy: {primary_alb_dns}")
        
        # Send alert
        message = f"""
        PRIMARY REGION HEALTH CHECK FAILED
        
        Primary ALB: {primary_alb_dns}
        Time: {context.aws_request_id}
        
        Consider activating disaster recovery if issue persists.
        """
        
        try:
            sns_client.publish(
                TopicArn=sns_topic_arn,
                Subject="Primary Region Health Alert",
                Message=message
            )
        except Exception as e:
            print(f"Failed to send SNS notification: {e}")
    
    # Check DR region if enabled
    dr_healthy = None
    if dr_alb_dns:
        dr_healthy = check_health(http, dr_alb_dns)
        if not dr_healthy:
            print(f"DR region also unhealthy: {dr_alb_dns}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'primary_healthy': primary_healthy,
            'dr_healthy': dr_healthy,
            'timestamp': context.aws_request_id
        })
    }

def check_health(http, alb_dns):
    """Check health of ALB endpoint"""
    if not alb_dns:
        return None
        
    try:
        url = f"http://{alb_dns}/health-simple.php"
        response = http.request('GET', url, timeout=10)
        return response.status == 200
    except Exception as e:
        print(f"Health check failed for {alb_dns}: {e}")
        return False