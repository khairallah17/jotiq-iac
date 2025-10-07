variable "name" {
  description = "Queue name"
  type        = string
}

variable "visibility_timeout" {
  description = "Visibility timeout"
  type        = number
  default     = 30
}

variable "retention_seconds" {
  description = "Message retention"
  type        = number
  default     = 345600
}

variable "receive_wait_seconds" {
  description = "Long polling wait time"
  type        = number
  default     = 10
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
}

variable "create_dlq" {
  description = "Create DLQ"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Max receive count before DLQ"
  type        = number
  default     = 5
}

variable "dlq_retention_seconds" {
  description = "DLQ retention"
  type        = number
  default     = 1209600
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
