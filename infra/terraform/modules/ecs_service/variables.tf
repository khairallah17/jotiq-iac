variable "name" {
  type        = string
  description = "Name of the ECS service"
}

variable "cluster_arn" {
  type        = string
  description = "ECS cluster ARN"
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "container_image" {
  type        = string
  description = "Container image URI"
}

variable "cpu" {
  type        = number
  description = "Task CPU units"
}

variable "memory" {
  type        = number
  description = "Task memory (MiB)"
}

variable "desired_count" {
  type        = number
  description = "Desired number of tasks"
}

variable "min_capacity" {
  type        = number
  description = "Minimum task count for scaling"
}

variable "max_capacity" {
  type        = number
  description = "Maximum task count for scaling"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for service networking"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups for service"
}

variable "assign_public_ip" {
  type        = bool
  description = "Assign a public IP address"
  default     = false
}

variable "listener_arn" {
  type        = string
  description = "ALB listener ARN"
  default     = ""
}

variable "listener_priority" {
  type        = number
  description = "Listener rule priority"
  default     = 200
}

variable "path_patterns" {
  type        = list(string)
  description = "Path patterns for listener rule"
  default     = ["/*"]
}

variable "host_headers" {
  type        = list(string)
  description = "Host headers for listener rule"
  default     = ["*"]
}

variable "health_check_path" {
  type        = string
  description = "Health check path"
  default     = "/health"
}

variable "service_port" {
  type        = number
  description = "Container/service port"
  default     = 80
}

variable "environment" {
  type        = map(string)
  description = "Environment variables"
  default     = {}
}

variable "secrets" {
  description = "Secrets for the container"
  type = list(object({
    name       = string
    value_from = string
  }))
  default = []
}

variable "aws_region" {
  description = "AWS region (for logs)"
  type        = string
}

variable "log_group_name" {
  description = "Log group name"
  type        = string
}

variable "log_group_arn" {
  description = "Log group ARN for IAM permissions"
  type        = string
}

variable "create_log_group" {
  description = "Whether to manage log group"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "log_kms_key_arn" {
  description = "KMS key for log encryption"
  type        = string
  default     = null
}

variable "execution_role_arn" {
  description = "Existing task execution role ARN"
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "Existing task role ARN"
  type        = string
  default     = null
}

variable "task_additional_policy_statements" {
  description = "Additional IAM policy statements"
  type        = list(any)
  default     = []
}

variable "secret_arns" {
  description = "Secrets Manager ARNs for IAM"
  type        = list(string)
  default     = []
}

variable "sqs_queue_arns" {
  description = "SQS queue ARNs for IAM"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs for IAM"
  type        = list(string)
  default     = []
}

variable "sqs_queue_metric" {
  description = "Custom metric config for queue-based scaling"
  type = object({
    metric_name  = string
    namespace    = string
    statistic    = string
    unit         = string
    dimensions   = list(object({
      name  = string
      value = string
    }))
    target_value = number
  })
  default = null
}

variable "enable_codedeploy" {
  description = "Enable CodeDeploy blue/green"
  type        = bool
  default     = false
}

variable "codedeploy_role_arn" {
  description = "Service role ARN for CodeDeploy"
  type        = string
  default     = null
}

variable "codedeploy_alarm_configuration" {
  description = "CodeDeploy alarm configuration"
  type = object({
    enabled     = bool
    alarm_names = list(string)
  })
  default = {
    enabled     = false
    alarm_names = []
  }
}

variable "enable_execute_command" {
  description = "Enable ECS exec"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID for target groups"
  type        = string
}

variable "container_health_check" {
  description = "Container-level health check configuration"
  type = object({
    command     = list(string)
    interval    = optional(number)
    timeout     = optional(number)
    retries     = optional(number)
    startPeriod = optional(number)
  })
  default = {
    command = ["CMD-SHELL", "curl -f http://localhost:80/health || exit 1"]
  }
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
