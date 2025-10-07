variable "project" {
  description = "Project name"
  type        = string
  default     = "jotiq"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "mongodb_uri_placeholder" {
  description = "Placeholder MongoDB URI"
  type        = string
  default     = "mongodb+srv://readonly:password@cluster.jotiq.mongodb.net/app"
}

variable "jwt_secret_placeholder" {
  description = "Placeholder JWT secret"
  type        = string
  default     = "change-me-jwt-secret"
}

variable "ses_smtp_user_placeholder" {
  description = "Placeholder SES SMTP user"
  type        = string
  default     = "AKIAIOSFODNN7EXAMPLE"
}

variable "ses_smtp_pass_placeholder" {
  description = "Placeholder SES SMTP password"
  type        = string
  default     = "super-secret-password"
}

variable "recovery_window_days" {
  description = "Secret recovery window"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
