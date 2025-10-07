variable "create_zone" {
  description = "Whether to create a new hosted zone"
  type        = bool
  default     = false
}

variable "zone_name" {
  description = "DNS zone name"
  type        = string
  default     = "jotiq.com"
}

variable "hosted_zone_id" {
  description = "Existing hosted zone ID"
  type        = string
  default     = null
}

variable "api_record" {
  description = "API record name"
  type        = string
  default     = "api.jotiq.com"
}

variable "app_record" {
  description = "App record name"
  type        = string
  default     = "app.jotiq.com"
}

variable "assets_record" {
  description = "Assets record name"
  type        = string
  default     = "assets.jotiq.com"
}

variable "alb_dns_name" {
  description = "ALB DNS name"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront domain name"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID"
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "ses_records" {
  description = "Additional SES verification records"
  type = map(object({
    name    = string
    type    = string
    ttl     = number
    records = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
