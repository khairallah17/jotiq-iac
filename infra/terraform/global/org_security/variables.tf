variable "region" {
  description = "AWS region to deploy org-wide security controls"
  type        = string
}

variable "monthly_budget_amount" {
  description = "Monthly budget limit for the account"
  type        = string
}

variable "budget_start" {
  description = "Start date for the budget (YYYY-MM-DD)"
  type        = string
}

variable "budget_notification_email" {
  description = "Email address to receive budget alerts"
  type        = string
}

variable "config_role_arn" {
  description = "IAM role ARN assumed by AWS Config"
  type        = string
}

variable "config_bucket" {
  description = "S3 bucket that stores AWS Config snapshots"
  type        = string
}

variable "config_sns_topic" {
  description = "SNS topic ARN for Config notifications"
  type        = string
}

variable "cloudtrail_bucket" {
  description = "S3 bucket for CloudTrail logs"
  type        = string
}

variable "cloudtrail_kms_key" {
  description = "KMS key ARN for encrypting CloudTrail logs"
  type        = string
}
