resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                       = "${var.name}-dlq"
  message_retention_seconds  = var.dlq_retention_seconds
  kms_master_key_id          = var.kms_key_arn
  visibility_timeout_seconds = var.visibility_timeout
  tags                       = var.tags
}

resource "aws_sqs_queue" "this" {
  name                              = var.name
  visibility_timeout_seconds        = var.visibility_timeout
  message_retention_seconds         = var.retention_seconds
  kms_master_key_id                 = var.kms_key_arn
  receive_wait_time_seconds         = var.receive_wait_seconds
  sqs_managed_sse_enabled           = false
  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null
  tags = var.tags
}
