variable "name" {
  description = "ALB name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
}

variable "access_logs_bucket" {
  description = "S3 bucket for access logs"
  type        = string
}

variable "access_logs_prefix" {
  description = "Prefix for access logs"
  type        = string
  default     = "alb"
}

variable "ingress_cidrs" {
  description = "Allowed ingress CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
