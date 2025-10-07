output "state_bucket_name" {
  description = "S3 bucket storing Terraform state"
  value       = aws_s3_bucket.state.id
}

output "lock_table_name" {
  description = "DynamoDB lock table"
  value       = aws_dynamodb_table.lock.name
}

output "kms_key_arn" {
  description = "KMS key ARN for backend encryption"
  value       = aws_kms_key.backend.arn
}
