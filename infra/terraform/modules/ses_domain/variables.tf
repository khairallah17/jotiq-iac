variable "domain" {
  description = "Domain to verify"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for feedback"
  type        = string
}

variable "create_route53_records" {
  description = "Whether to create Route53 records within this module"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
