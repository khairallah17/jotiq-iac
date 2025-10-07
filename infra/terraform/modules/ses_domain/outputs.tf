output "identity_arn" {
  description = "SES domain identity ARN"
  value       = aws_ses_domain_identity.this.arn
}

output "dkim_tokens" {
  description = "DKIM tokens"
  value       = aws_ses_domain_dkim.this.dkim_tokens
}

output "verification_token" {
  description = "SES verification token"
  value       = aws_ses_domain_identity.this.verification_token
}
