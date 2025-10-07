terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  environment = var.environment
  azs         = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = merge(var.default_tags, {
    Project    = "JOTIQ"
    Env        = local.environment
  })
  observability_services = [
    {
      name              = "api"
      retention_in_days = var.log_retention_days
      cpu_threshold     = var.api_cpu_alarm_threshold
      memory_threshold  = var.api_memory_alarm_threshold
    },
    {
      name              = "web"
      retention_in_days = var.log_retention_days
      cpu_threshold     = var.web_cpu_alarm_threshold
      memory_threshold  = var.web_memory_alarm_threshold
    },
    {
      name              = "worker"
      retention_in_days = var.log_retention_days
      cpu_threshold     = var.worker_cpu_alarm_threshold
      memory_threshold  = var.worker_memory_alarm_threshold
    }
  ]
}

resource "aws_kms_key" "general" {
  description         = "General purpose key for ${local.environment}"
  enable_key_rotation = true
  tags                = local.tags
}

resource "aws_kms_alias" "general" {
  name          = "alias/jotiq-${local.environment}-general"
  target_key_id = aws_kms_key.general.key_id
}

resource "aws_kms_key" "sns" {
  description         = "SNS encryption key for ${local.environment}"
  enable_key_rotation = true
  tags                = local.tags
}

resource "aws_kms_alias" "sns" {
  name          = "alias/jotiq-${local.environment}-sns"
  target_key_id = aws_kms_key.sns.key_id
}

module "vpc" {
  source     = "../../modules/vpc"
  name       = "jotiq-${local.environment}"
  cidr_block = var.vpc_cidr
  azs        = local.azs
  enable_nat = var.enable_nat_gateway
  tags       = local.tags
}

module "endpoints" {
  source                  = "../../modules/endpoints"
  name                    = "jotiq-${local.environment}"
  vpc_id                  = module.vpc.vpc_id
  region                  = var.region
  private_route_table_ids = module.vpc.private_route_table_ids
  subnet_ids              = module.vpc.private_subnet_ids
  allowed_cidrs           = [var.vpc_cidr]
  tags                    = local.tags
}

module "secrets" {
  source      = "../../modules/secrets"
  project     = "jotiq"
  environment = local.environment
  tags        = local.tags
}

module "s3_logs" {
  source     = "../../modules/s3_bucket"
  name       = "jotiq-${local.environment}-logs"
  kms_key_arn = aws_kms_key.general.arn
  enable_versioning = true
  log_bucket = null
  tags       = local.tags
}

module "s3_assets" {
  source     = "../../modules/s3_bucket"
  name       = "jotiq-${local.environment}-assets"
  kms_key_arn = aws_kms_key.general.arn
  enable_versioning = true
  log_bucket = module.s3_logs.bucket_id
  log_prefix = "assets"
  tags       = local.tags
}

module "s3_backups" {
  source     = "../../modules/s3_bucket"
  name       = "jotiq-${local.environment}-backups"
  kms_key_arn = aws_kms_key.general.arn
  enable_versioning = true
  log_bucket = module.s3_logs.bucket_id
  log_prefix = "backups"
  tags       = local.tags
}

module "cloudfront" {
  source                 = "../../modules/cloudfront_waf"
  domain_name            = var.assets_domain
  aliases                = [var.assets_domain]
  s3_bucket_domain_name  = "${module.s3_assets.bucket_id}.s3.amazonaws.com"
  acm_certificate_arn    = var.cloudfront_acm_certificate_arn
  log_bucket_domain_name = "${module.s3_logs.bucket_id}.s3.amazonaws.com"
  log_prefix             = "cloudfront"
  web_acl_arn            = var.cloudfront_waf_arn
  price_class            = var.cloudfront_price_class
  tags                   = local.tags
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = module.s3_assets.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          CanonicalUser = module.cloudfront.origin_access_identity_canonical_user_id
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3_assets.bucket_arn}/*"
      }
    ]
  })
}

resource "aws_sns_topic" "ses_feedback" {
  name              = "jotiq-${local.environment}-ses-feedback"
  kms_master_key_id = aws_kms_key.sns.arn
  tags              = local.tags
}

module "ses_tx" {
  source         = "../../modules/ses_domain"
  domain         = var.ses_transactional_domain
  hosted_zone_id = var.hosted_zone_id
  sns_topic_arn  = aws_sns_topic.ses_feedback.arn
  create_route53_records = false
  tags           = local.tags
}

module "ses_mkt" {
  source         = "../../modules/ses_domain"
  domain         = var.ses_marketing_domain
  hosted_zone_id = var.hosted_zone_id
  sns_topic_arn  = aws_sns_topic.ses_feedback.arn
  create_route53_records = false
  tags           = local.tags
}

module "sqs_email_outbox" {
  source                = "../../modules/sqs_queue"
  name                  = "jotiq-${local.environment}-email-outbox"
  kms_key_arn           = aws_kms_key.general.arn
  visibility_timeout    = var.worker_visibility_timeout
  retention_seconds     = var.sqs_retention_seconds
  max_receive_count     = var.sqs_max_receive_count
  tags                  = local.tags
}

module "ecr_api" {
  source     = "../../modules/ecr_repo"
  name       = "jotiq-${local.environment}-api"
  kms_key_arn = aws_kms_key.general.arn
  tags       = local.tags
}

module "ecr_web" {
  source     = "../../modules/ecr_repo"
  name       = "jotiq-${local.environment}-web"
  kms_key_arn = aws_kms_key.general.arn
  tags       = local.tags
}

module "ecr_worker" {
  source     = "../../modules/ecr_repo"
  name       = "jotiq-${local.environment}-worker"
  kms_key_arn = aws_kms_key.general.arn
  tags       = local.tags
}

module "ecs_cluster" {
  source                  = "../../modules/ecs_cluster"
  name                    = "jotiq-${local.environment}"
  enable_container_insights = true
  enable_fargate_spot     = var.enable_fargate_spot
  tags                    = local.tags
}

module "alb" {
  source                = "../../modules/alb"
  name                  = "jotiq-${local.environment}-alb"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids
  acm_certificate_arn   = var.alb_acm_certificate_arn
  access_logs_bucket    = module.s3_logs.bucket_id
  access_logs_prefix    = "alb"
  tags                  = local.tags
}

locals {
  alb_arn_suffix = element(split("loadbalancer/", module.alb.alb_arn), 1)
  ses_records_map = merge(
    {
      tx_verification = {
        name    = "_amazonses.${var.ses_transactional_domain}"
        type    = "TXT"
        ttl     = 600
        records = [module.ses_tx.verification_token]
      }
    },
    {
      mkt_verification = {
        name    = "_amazonses.${var.ses_marketing_domain}"
        type    = "TXT"
        ttl     = 600
        records = [module.ses_mkt.verification_token]
      }
    },
    {
      tx_spf = {
        name    = var.ses_transactional_domain
        type    = "TXT"
        ttl     = 600
        records = ["v=spf1 include:amazonses.com -all"]
      }
    },
    {
      mkt_spf = {
        name    = var.ses_marketing_domain
        type    = "TXT"
        ttl     = 600
        records = ["v=spf1 include:amazonses.com -all"]
      }
    },
    { for idx, token in module.ses_tx.dkim_tokens : "tx_dkim_${idx}" => {
        name    = "${token}._domainkey.${var.ses_transactional_domain}"
        type    = "CNAME"
        ttl     = 600
        records = ["${token}.dkim.amazonses.com"]
      }
    },
    { for idx, token in module.ses_mkt.dkim_tokens : "mkt_dkim_${idx}" => {
        name    = "${token}._domainkey.${var.ses_marketing_domain}"
        type    = "CNAME"
        ttl     = 600
        records = ["${token}.dkim.amazonses.com"]
      }
    }
  )
}

module "observability" {
  source                = "../../modules/observability"
  project               = "jotiq"
  environment           = local.environment
  services              = local.observability_services
  log_kms_key_arn       = aws_kms_key.general.arn
  sns_kms_key_arn       = aws_kms_key.sns.arn
  alb_arn_suffix        = local.alb_arn_suffix
  alb_latency_threshold = var.alb_latency_threshold
  ecs_cluster_name      = module.ecs_cluster.cluster_name
  sqs_queue_name        = module.sqs_email_outbox.queue_name
  sqs_max_messages      = var.sqs_max_messages
  sqs_max_age_seconds   = var.sqs_max_age_seconds
  ses_identity          = var.ses_metrics_identity
  ses_bounce_threshold    = var.ses_bounce_threshold
  ses_complaint_threshold = var.ses_complaint_threshold
  tags                  = local.tags
}

module "iam_roles" {
  source         = "../../modules/iam_roles"
  environment    = local.environment
  log_group_arns = values(module.observability.log_group_arns)
  secret_arns    = values(module.secrets.secret_arns)
  s3_bucket_arns = [module.s3_assets.bucket_arn]
  sqs_queue_arns = [module.sqs_email_outbox.queue_arn]
  github_org     = var.github_org
  github_repo    = var.github_repo
  tags           = local.tags
}

resource "aws_security_group" "ecs_service" {
  name        = "jotiq-${local.environment}-ecs-sg"
  description = "Allow traffic from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "App from ALB"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [module.alb.security_group_id]
  }

  ingress {
    description = "HTTPS egress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

locals {
  api_log_group_name = module.observability.log_group_names["api"]
  web_log_group_name = module.observability.log_group_names["web"]
  worker_log_group_name = module.observability.log_group_names["worker"]
  api_log_group_arn = module.observability.log_group_arns["api"]
  web_log_group_arn = module.observability.log_group_arns["web"]
  worker_log_group_arn = module.observability.log_group_arns["worker"]
}

module "ecs_service_api" {
  source             = "../../modules/ecs_service"
  name               = "jotiq-${local.environment}-api"
  cluster_arn        = module.ecs_cluster.cluster_id
  cluster_name       = module.ecs_cluster.cluster_name
  container_image    = var.api_image
  cpu                = var.api_cpu
  memory             = var.api_memory
  desired_count      = var.api_desired_count
  min_capacity       = var.api_min_capacity
  max_capacity       = var.api_max_capacity
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.ecs_service.id]
  assign_public_ip   = false
  listener_arn       = module.alb.https_listener_arn
  listener_priority  = 100
  path_patterns      = ["/api/*"]
  host_headers       = [var.api_domain]
  health_check_path  = "/health"
  service_port       = 3000
  environment        = var.api_environment
  secrets            = [
    { name = "MONGODB_URI", value_from = module.secrets.secret_arns["MONGODB_URI"] },
    { name = "JWT_SECRET", value_from = module.secrets.secret_arns["JWT_SECRET"] }
  ]
  aws_region         = var.region
  log_group_name     = local.api_log_group_name
  log_group_arn      = local.api_log_group_arn
  create_log_group   = false
  execution_role_arn = module.iam_roles.execution_role_arn
  task_role_arn      = module.iam_roles.task_role_arn
  secret_arns        = values(module.secrets.secret_arns)
  s3_bucket_arns     = [module.s3_assets.bucket_arn]
  sqs_queue_arns     = [module.sqs_email_outbox.queue_arn]
  vpc_id             = module.vpc.vpc_id
  enable_codedeploy  = true
  codedeploy_role_arn = module.iam_roles.codedeploy_role_arn
  codedeploy_alarm_configuration = {
    enabled     = true
    alarm_names = [module.observability.alb_5xx_alarm_name]
  }
  enable_execute_command = true
  tags              = local.tags
}

module "ecs_service_web" {
  source             = "../../modules/ecs_service"
  name               = "jotiq-${local.environment}-web"
  cluster_arn        = module.ecs_cluster.cluster_id
  cluster_name       = module.ecs_cluster.cluster_name
  container_image    = var.web_image
  cpu                = var.web_cpu
  memory             = var.web_memory
  desired_count      = var.web_desired_count
  min_capacity       = var.web_min_capacity
  max_capacity       = var.web_max_capacity
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.ecs_service.id]
  listener_arn       = module.alb.https_listener_arn
  listener_priority  = 110
  path_patterns      = ["/*"]
  host_headers       = [var.app_domain]
  health_check_path  = "/health"
  service_port       = 3000
  environment        = var.web_environment
  secrets            = [
    { name = "MONGODB_URI", value_from = module.secrets.secret_arns["MONGODB_URI"] }
  ]
  aws_region         = var.region
  log_group_name     = local.web_log_group_name
  log_group_arn      = local.web_log_group_arn
  create_log_group   = false
  execution_role_arn = module.iam_roles.execution_role_arn
  task_role_arn      = module.iam_roles.task_role_arn
  secret_arns        = values(module.secrets.secret_arns)
  s3_bucket_arns     = [module.s3_assets.bucket_arn]
  sqs_queue_arns     = [module.sqs_email_outbox.queue_arn]
  vpc_id             = module.vpc.vpc_id
  enable_codedeploy  = true
  codedeploy_role_arn = module.iam_roles.codedeploy_role_arn
  codedeploy_alarm_configuration = {
    enabled     = true
    alarm_names = [module.observability.alb_latency_alarm_name]
  }
  enable_execute_command = true
  tags              = local.tags
}

module "ecs_service_worker" {
  source             = "../../modules/ecs_service"
  name               = "jotiq-${local.environment}-worker"
  cluster_arn        = module.ecs_cluster.cluster_id
  cluster_name       = module.ecs_cluster.cluster_name
  container_image    = var.worker_image
  cpu                = var.worker_cpu
  memory             = var.worker_memory
  desired_count      = var.worker_desired_count
  min_capacity       = var.worker_min_capacity
  max_capacity       = var.worker_max_capacity
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.ecs_service.id]
  assign_public_ip   = false
  listener_arn       = ""
  health_check_path  = "/health"
  service_port       = 3000
  environment        = var.worker_environment
  secrets            = [
    { name = "MONGODB_URI", value_from = module.secrets.secret_arns["MONGODB_URI"] },
    { name = "SES_SMTP_USER", value_from = module.secrets.secret_arns["SES_SMTP_USER"] },
    { name = "SES_SMTP_PASS", value_from = module.secrets.secret_arns["SES_SMTP_PASS"] }
  ]
  aws_region         = var.region
  log_group_name     = local.worker_log_group_name
  log_group_arn      = local.worker_log_group_arn
  create_log_group   = false
  execution_role_arn = module.iam_roles.execution_role_arn
  task_role_arn      = module.iam_roles.task_role_arn
  secret_arns        = values(module.secrets.secret_arns)
  sqs_queue_arns     = [module.sqs_email_outbox.queue_arn]
  s3_bucket_arns     = [module.s3_assets.bucket_arn]
  vpc_id             = module.vpc.vpc_id
  enable_codedeploy  = false
  sqs_queue_metric = {
    metric_name  = "ApproximateNumberOfMessagesVisible"
    namespace    = "AWS/SQS"
    statistic    = "Average"
    unit         = "Count"
    dimensions   = [{ name = "QueueName", value = module.sqs_email_outbox.queue_name }]
    target_value = var.worker_queue_target
  }
  enable_execute_command = true
  tags              = local.tags
}

module "route53" {
  source                    = "../../modules/route53"
  create_zone               = var.create_hosted_zone
  zone_name                 = var.domain
  hosted_zone_id            = var.hosted_zone_id
  api_record                = var.api_domain
  app_record                = var.app_domain
  assets_record             = var.assets_domain
  alb_dns_name              = module.alb.alb_dns_name
  alb_zone_id               = module.alb.alb_zone_id
  cloudfront_domain_name    = module.cloudfront.distribution_domain_name
  ses_records               = local.ses_records_map
  tags = local.tags
}

resource "aws_ses_domain_identity_verification" "tx" {
  domain     = var.ses_transactional_domain
  depends_on = [module.route53]
}

resource "aws_ses_domain_identity_verification" "mkt" {
  domain     = var.ses_marketing_domain
  depends_on = [module.route53]
}

