variable "name" {
  description = "Bucket name"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
}

variable "log_bucket" {
  description = "Log destination bucket"
  type        = string
  default     = null
}

variable "log_prefix" {
  description = "Log prefix"
  type        = string
  default     = "logs"
}

variable "cloudfront_access_identity" {
  description = "CloudFront origin access identity ARN"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
