output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_domain_name" {
  description = "Distribution domain name"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "origin_access_identity_path" {
  description = "Origin access identity path"
  value       = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
}

output "origin_access_identity_arn" {
  description = "Origin access identity IAM ARN"
  value       = aws_cloudfront_origin_access_identity.this.iam_arn
}

output "origin_access_identity_canonical_user_id" {
  description = "Origin access identity canonical user ID"
  value       = aws_cloudfront_origin_access_identity.this.s3_canonical_user_id
}
