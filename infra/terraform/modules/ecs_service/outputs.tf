output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "target_group_arn" {
  description = "Primary target group ARN"
  value       = local.enable_alb ? aws_lb_target_group.blue[0].arn : null
}

output "task_definition_arn" {
  description = "Task definition ARN"
  value       = aws_ecs_task_definition.this.arn
}
