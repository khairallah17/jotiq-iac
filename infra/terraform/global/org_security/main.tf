terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_budgets_budget" "monthly" {
  name              = "jotiq-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_amount
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = var.budget_start

  cost_filters = {
    TagKeyValue = "Project$JOTIQ"
  }

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "FORECASTED"

    subscriber {
      subscription_type = "EMAIL"
      address           = var.budget_notification_email
    }
  }
}

resource "aws_guardduty_detector" "this" {
  enable = true
}

resource "aws_config_configuration_recorder" "this" {
  name     = "jotiq-config-recorder"
  role_arn = var.config_role_arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true
}

resource "aws_config_delivery_channel" "this" {
  name           = "jotiq-config-channel"
  s3_bucket_name = var.config_bucket
  sns_topic_arn  = var.config_sns_topic

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_cloudtrail" "this" {
  name                          = "jotiq-org-trail"
  s3_bucket_name                = var.cloudtrail_bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = var.cloudtrail_kms_key

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
}

resource "aws_securityhub_account" "this" {}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.this]
}

