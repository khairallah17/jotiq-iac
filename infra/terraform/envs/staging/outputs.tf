output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = module.cloudfront.distribution_domain_name
}

output "api_service_name" {
  description = "API ECS service name"
  value       = module.ecs_service_api.service_name
}

output "web_service_name" {
  description = "Web ECS service name"
  value       = module.ecs_service_web.service_name
}

output "worker_service_name" {
  description = "Worker ECS service name"
  value       = module.ecs_service_worker.service_name
}

output "email_queue_arn" {
  description = "Email outbox queue ARN"
  value       = module.sqs_email_outbox.queue_arn
}

output "observability_dashboard" {
  description = "CloudWatch dashboard name"
  value       = module.observability.dashboard_name
}

output "alerts_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = module.observability.sns_topic_arn
}

output "github_oidc_role_arn" {
  description = "GitHub Actions deploy role ARN"
  value       = module.iam_roles.github_oidc_role_arn
}

output "secrets" {
  description = "Secrets Manager ARNs"
  value       = module.secrets.secret_arns
}
