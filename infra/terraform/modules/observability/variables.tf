variable "project" {
  description = "Project name"
  type        = string
  default     = "jotiq"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "services" {
  description = "List of ECS services"
  type = list(object({
    name               = string
    retention_in_days  = number
    cpu_threshold      = number
    memory_threshold   = number
  }))
}

variable "log_kms_key_arn" {
  description = "KMS key for log encryption"
  type        = string
  default     = null
}

variable "sns_kms_key_arn" {
  description = "KMS key for SNS"
  type        = string
  default     = null
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix"
  type        = string
}

variable "alb_latency_threshold" {
  description = "ALB latency threshold"
  type        = number
  default     = 0.5
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "sqs_queue_name" {
  description = "Primary SQS queue name"
  type        = string
}

variable "sqs_max_messages" {
  description = "Max visible messages before alarm"
  type        = number
  default     = 100
}

variable "sqs_max_age_seconds" {
  description = "Max age of oldest message"
  type        = number
  default     = 300
}

variable "ses_identity" {
  description = "SES identity"
  type        = string
}

variable "ses_bounce_threshold" {
  description = "SES bounce rate threshold"
  type        = number
  default     = 5
}

variable "ses_complaint_threshold" {
  description = "SES complaint rate threshold"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
