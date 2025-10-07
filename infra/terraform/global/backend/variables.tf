variable "state_bucket" {
  description = "Name of the S3 bucket that stores Terraform state"
  type        = string
}

variable "state_key_prefix" {
  description = "Prefix for storing state files"
  type        = string
  default     = "global/backend"
}

variable "lock_table" {
  description = "DynamoDB table name for state locking"
  type        = string
}

variable "region" {
  description = "AWS region for backend resources"
  type        = string
}

variable "tags" {
  description = "Common tags applied to backend resources"
  type        = map(string)
  default = {
    Project    = "JOTIQ"
    Owner      = "PlatformTeam"
    CostCenter = "Shared"
  }
}
