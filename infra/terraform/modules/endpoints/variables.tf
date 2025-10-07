variable "name" {
  description = "Prefix for endpoint resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "private_route_table_ids" {
  description = "Private route table IDs"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Subnet IDs for interface endpoints"
  type        = list(string)
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to reach endpoints"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}
