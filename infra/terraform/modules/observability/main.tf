resource "aws_cloudwatch_log_group" "service" {
  for_each = { for svc in var.services : svc.name => svc }

  name              = "/aws/ecs/${var.project}/${var.environment}/${each.value.name}"
  retention_in_days = each.value.retention_in_days
  kms_key_id        = var.log_kms_key_arn
  tags              = var.tags
}

resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.environment}-alerts"
  kms_master_key_id = var.sns_kms_key_arn
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project}-${var.environment}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "High rate of 5XX on ALB"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${var.project}-${var.environment}-alb-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = var.alb_latency_threshold
  alarm_description   = "High target response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  for_each = { for svc in var.services : svc.name => svc }

  alarm_name          = "${var.project}-${var.environment}-${each.key}-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = each.value.cpu_threshold
  alarm_description   = "High CPU for ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = each.value.name
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  for_each = { for svc in var.services : svc.name => svc }

  alarm_name          = "${var.project}-${var.environment}-${each.key}-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = each.value.memory_threshold
  alarm_actions       = [aws_sns_topic.alerts.arn]
  alarm_description   = "High memory for ${each.key}"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = each.value.name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_depth" {
  alarm_name          = "${var.project}-${var.environment}-sqs-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.sqs_max_messages
  alarm_description   = "Queue depth high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = var.sqs_queue_name
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_age" {
  alarm_name          = "${var.project}-${var.environment}-sqs-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.sqs_max_age_seconds
  alarm_description   = "Queue age high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = var.sqs_queue_name
  }
}

resource "aws_cloudwatch_metric_alarm" "ses_bounce" {
  alarm_name          = "${var.project}-${var.environment}-ses-bounce"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Reputation.BounceRate"
  namespace           = "AWS/SES"
  period              = 300
  statistic           = "Average"
  threshold           = var.ses_bounce_threshold
  alarm_description   = "High SES bounce rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    Identity = var.ses_identity
  }
}

resource "aws_cloudwatch_metric_alarm" "ses_complaint" {
  alarm_name          = "${var.project}-${var.environment}-ses-complaint"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Reputation.ComplaintRate"
  namespace           = "AWS/SES"
  period              = 300
  statistic           = "Average"
  threshold           = var.ses_complaint_threshold
  alarm_description   = "High SES complaint rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    Identity = var.ses_identity
  }
}

locals {
  dashboard_widgets = jsonencode({
    widgets = [
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title = "ALB 5XX & Latency"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title = "SQS Depth & Age"
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.sqs_queue_name],
            ["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", var.sqs_queue_name]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type = "metric"
        width = 24
        height = 6
        properties = {
          title = "ECS CPU"
          metrics = [for svc in var.services : ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", svc.name]]
          period = 300
          stat   = "Average"
        }
      },
      {
        type = "metric"
        width = 24
        height = 6
        properties = {
          title = "ECS Memory"
          metrics = [for svc in var.services : ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", svc.name]]
          period = 300
          stat   = "Average"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.project}-${var.environment}-overview"
  dashboard_body = local.dashboard_widgets
}
