output "dr_automation_function_name" {
  description = "Name of the DR automation Lambda function"
  value       = aws_lambda_function.dr_automation.function_name
}

output "health_monitor_function_name" {
  description = "Name of the health monitor Lambda function"
  value       = aws_lambda_function.health_monitor.function_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}