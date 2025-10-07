output "log_group_names" {
  description = "Map of log group names"
  value       = { for name, group in aws_cloudwatch_log_group.service : name => group.name }
}

output "log_group_arns" {
  description = "Map of log group ARNs"
  value       = { for name, group in aws_cloudwatch_log_group.service : name => group.arn }
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}

output "alb_5xx_alarm_name" {
  description = "ALB 5XX alarm name"
  value       = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name
}

output "alb_latency_alarm_name" {
  description = "ALB latency alarm name"
  value       = aws_cloudwatch_metric_alarm.alb_latency.alarm_name
}
