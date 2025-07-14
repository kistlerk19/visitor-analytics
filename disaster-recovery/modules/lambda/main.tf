# Lambda function for DR automation
resource "aws_lambda_function" "dr_automation" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-dr-automation"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      CLUSTER_NAME = var.project_name
      DR_REGION    = var.dr_region
      PRIMARY_REGION = var.primary_region
    }
  }

  tags = var.tags
}

# Lambda function for health monitoring
resource "aws_lambda_function" "health_monitor" {
  filename         = data.archive_file.health_lambda_zip.output_path
  function_name    = "${var.project_name}-health-monitor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "health.handler"
  source_code_hash = data.archive_file.health_lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      PRIMARY_ALB_DNS = var.primary_alb_dns
      DR_ALB_DNS     = var.dr_alb_dns
      SNS_TOPIC_ARN  = aws_sns_topic.alerts.arn
    }
  }

  tags = var.tags
}

# DR Lambda function (disabled by default)
resource "aws_lambda_function" "dr_automation_replica" {
  count            = var.enable_dr ? 1 : 0
  provider         = aws.dr
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-dr-automation"
  role            = aws_iam_role.dr_lambda_role[0].arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      CLUSTER_NAME = var.project_name
      DR_REGION    = var.dr_region
      PRIMARY_REGION = var.primary_region
    }
  }

  tags = var.tags
}

# Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source {
    content = templatefile("${path.module}/lambda_function.py", {
      cluster_name = var.project_name
    })
    filename = "index.py"
  }
}

data "archive_file" "health_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/health_lambda.zip"
  source {
    content  = file("${path.module}/health_monitor.py")
    filename = "health.py"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "dr_lambda_role" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  name     = "${var.project_name}-lambda-role-dr"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda execution policy
resource "aws_iam_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "rds:PromoteReadReplica",
          "rds:DescribeDBInstances",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "dr_lambda_policy" {
  count      = var.enable_dr ? 1 : 0
  role       = aws_iam_role.dr_lambda_role[0].name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# SNS topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-dr-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# CloudWatch Event Rule for health monitoring
resource "aws_cloudwatch_event_rule" "health_check" {
  name                = "${var.project_name}-health-check"
  description         = "Trigger health check every 5 minutes"
  schedule_expression = "rate(5 minutes)"
  tags               = var.tags
}

resource "aws_cloudwatch_event_target" "health_check" {
  rule      = aws_cloudwatch_event_rule.health_check.name
  target_id = "HealthCheckTarget"
  arn       = aws_lambda_function.health_monitor.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health_check.arn
}