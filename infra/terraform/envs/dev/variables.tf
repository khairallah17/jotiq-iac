variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateways"
  type        = bool
  default     = true
}

variable "enable_fargate_spot" {
  description = "Enable Fargate Spot"
  type        = bool
  default     = true
}

variable "default_tags" {
  description = "Base tags"
  type        = map(string)
  default     = {
    Owner      = "PlatformTeam"
    CostCenter = "SaaS"
  }
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "api_cpu_alarm_threshold" {
  type    = number
  default = 75
}

variable "api_memory_alarm_threshold" {
  type    = number
  default = 80
}

variable "web_cpu_alarm_threshold" {
  type    = number
  default = 70
}

variable "web_memory_alarm_threshold" {
  type    = number
  default = 75
}

variable "worker_cpu_alarm_threshold" {
  type    = number
  default = 65
}

variable "worker_memory_alarm_threshold" {
  type    = number
  default = 70
}

variable "alb_latency_threshold" {
  description = "ALB latency threshold in seconds"
  type        = number
  default     = 0.75
}

variable "sqs_max_messages" {
  description = "Max visible messages before alarm"
  type        = number
  default     = 200
}

variable "sqs_max_age_seconds" {
  description = "Max age of oldest message"
  type        = number
  default     = 600
}

variable "sqs_retention_seconds" {
  description = "SQS retention period"
  type        = number
  default     = 604800
}

variable "sqs_max_receive_count" {
  description = "Max receive count before DLQ"
  type        = number
  default     = 5
}

variable "worker_visibility_timeout" {
  description = "Worker visibility timeout"
  type        = number
  default     = 60
}

variable "worker_queue_target" {
  description = "Target messages for worker autoscaling"
  type        = number
  default     = 10
}

variable "domain" {
  description = "Primary domain"
  type        = string
}

variable "create_hosted_zone" {
  description = "Whether to create the hosted zone"
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "Existing hosted zone ID"
  type        = string
  default     = null
}

variable "api_domain" {
  description = "API domain"
  type        = string
}

variable "app_domain" {
  description = "App domain"
  type        = string
}

variable "assets_domain" {
  description = "Assets domain"
  type        = string
}

variable "alb_acm_certificate_arn" {
  description = "ACM cert for ALB"
  type        = string
}

variable "cloudfront_acm_certificate_arn" {
  description = "ACM cert for CloudFront"
  type        = string
}

variable "cloudfront_waf_arn" {
  description = "Optional WAF ARN"
  type        = string
  default     = null
}

variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "ses_transactional_domain" {
  description = "Transactional SES domain"
  type        = string
}

variable "ses_marketing_domain" {
  description = "Marketing SES domain"
  type        = string
}

variable "ses_metrics_identity" {
  description = "SES identity to monitor"
  type        = string
}

variable "ses_bounce_threshold" {
  description = "Bounce rate threshold"
  type        = number
  default     = 5
}

variable "ses_complaint_threshold" {
  description = "Complaint rate threshold"
  type        = number
  default     = 1
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "api_image" {
  description = "API image URI"
  type        = string
}

variable "api_cpu" {
  type    = number
  default = 512
}

variable "api_memory" {
  type    = number
  default = 1024
}

variable "api_desired_count" {
  type    = number
  default = 2
}

variable "api_min_capacity" {
  type    = number
  default = 2
}

variable "api_max_capacity" {
  type    = number
  default = 6
}

variable "api_environment" {
  description = "API environment variables"
  type        = map(string)
  default     = {}
}

variable "web_image" {
  description = "Web image URI"
  type        = string
}

variable "web_cpu" {
  type    = number
  default = 512
}

variable "web_memory" {
  type    = number
  default = 1024
}

variable "web_desired_count" {
  type    = number
  default = 2
}

variable "web_min_capacity" {
  type    = number
  default = 2
}

variable "web_max_capacity" {
  type    = number
  default = 6
}

variable "web_environment" {
  description = "Web environment variables"
  type        = map(string)
  default     = {}
}

variable "worker_image" {
  description = "Worker image URI"
  type        = string
}

variable "worker_cpu" {
  type    = number
  default = 512
}

variable "worker_memory" {
  type    = number
  default = 1024
}

variable "worker_desired_count" {
  type    = number
  default = 2
}

variable "worker_min_capacity" {
  type    = number
  default = 1
}

variable "worker_max_capacity" {
  type    = number
  default = 4
}

variable "worker_environment" {
  description = "Worker environment variables"
  type        = map(string)
  default     = {}
}
