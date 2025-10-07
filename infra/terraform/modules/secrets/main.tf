resource "aws_kms_key" "this" {
  description         = "Secrets Manager encryption key for ${var.project}-${var.environment}"
  enable_key_rotation = true
  deletion_window_in_days = 10
  tags = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project}-${var.environment}-secrets"
  target_key_id = aws_kms_key.this.key_id
}

locals {
  secrets = {
    MONGODB_URI   = var.mongodb_uri_placeholder
    JWT_SECRET    = var.jwt_secret_placeholder
    SES_SMTP_USER = var.ses_smtp_user_placeholder
    SES_SMTP_PASS = var.ses_smtp_pass_placeholder
  }
}

resource "aws_secretsmanager_secret" "this" {
  for_each = local.secrets

  name                    = "${var.project}/${var.environment}/${each.key}"
  kms_key_id              = aws_kms_key.this.arn
  recovery_window_in_days = var.recovery_window_days
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = local.secrets

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value
}
