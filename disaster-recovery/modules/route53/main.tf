# Route53 hosted zone for failover routing
resource "aws_route53_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
  tags  = var.tags
}

# Primary region record with failover routing
resource "aws_route53_record" "primary" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 60

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier = "primary"
  records        = [var.primary_alb_dns]

  health_check_id = aws_route53_health_check.primary[0].id
}

# DR region record with failover routing
resource "aws_route53_record" "dr" {
  count   = var.enable_dr && var.domain_name != "" ? 1 : 0
  zone_id = aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 60

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "dr"
  records        = [var.dr_alb_dns]
}

# Health check for primary region
resource "aws_route53_health_check" "primary" {
  count                           = var.domain_name != "" ? 1 : 0
  fqdn                           = var.primary_alb_dns
  port                           = 80
  type                           = "HTTP"
  resource_path                  = "/health-simple.php"
  failure_threshold              = 3
  request_interval               = 30
  cloudwatch_alarm_region        = var.primary_region
  cloudwatch_alarm_name          = "${var.project_name}-primary-health"
  insufficient_data_health_status = "Failure"

  tags = merge(var.tags, {
    Name = "${var.project_name}-primary-health-check"
  })
}

# CloudWatch alarm for health check
resource "aws_cloudwatch_metric_alarm" "primary_health" {
  count               = var.domain_name != "" ? 1 : 0
  alarm_name          = "${var.project_name}-primary-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This metric monitors primary region health"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary[0].id
  }

  tags = var.tags
}