output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.this.id
}

output "budget_id" {
  description = "Monthly budget name"
  value       = aws_budgets_budget.monthly.name
}

output "securityhub_subscriptions" {
  description = "SecurityHub standard subscriptions"
  value       = [aws_securityhub_standards_subscription.cis.standards_arn]
}
