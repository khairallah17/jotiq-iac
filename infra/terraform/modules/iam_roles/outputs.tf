output "task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task.arn
}

output "execution_role_arn" {
  description = "ECS execution role ARN"
  value       = aws_iam_role.ecs_execution.arn
}

output "github_oidc_role_arn" {
  description = "GitHub Actions OIDC role ARN"
  value       = aws_iam_role.github.arn
}

output "codedeploy_role_arn" {
  description = "CodeDeploy service role ARN"
  value       = aws_iam_role.codedeploy.arn
}
