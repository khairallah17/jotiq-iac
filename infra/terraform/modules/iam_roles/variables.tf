variable "project" {
  description = "Project name"
  type        = string
  default     = "jotiq"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "log_group_arns" {
  description = "CloudWatch log group ARNs"
  type        = list(string)
  default     = []
}

variable "secret_arns" {
  description = "Secrets Manager ARNs"
  type        = list(string)
  default     = []
}

variable "sqs_queue_arns" {
  description = "SQS queue ARNs"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs"
  type        = list(string)
  default     = []
}

variable "additional_task_statements" {
  description = "Additional IAM statements for task role"
  type        = list(any)
  default     = []
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
