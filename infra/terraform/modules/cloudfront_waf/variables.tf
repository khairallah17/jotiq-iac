variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "aliases" {
  description = "Alternate domain names"
  type        = list(string)
  default     = []
}

variable "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1"
  type        = string
}

variable "log_bucket_domain_name" {
  description = "S3 bucket domain for logs"
  type        = string
}

variable "log_prefix" {
  description = "Log prefix"
  type        = string
  default     = "cloudfront"
}

variable "cache_policy_id" {
  description = "Cache policy ID"
  type        = string
  default     = null
}

variable "web_acl_arn" {
  description = "Optional WAF ARN"
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "default_root_object" {
  description = "Default root object"
  type        = string
  default     = "index.html"
}

variable "comment" {
  description = "Distribution comment"
  type        = string
  default     = "JOTIQ assets distribution"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
