output "queue_url" {
  description = "Queue URL"
  value       = aws_sqs_queue.this.id
}

output "queue_arn" {
  description = "Queue ARN"
  value       = aws_sqs_queue.this.arn
}

output "dlq_arn" {
  description = "DLQ ARN"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "queue_name" {
  description = "Queue name"
  value       = aws_sqs_queue.this.name
}
