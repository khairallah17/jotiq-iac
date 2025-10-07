locals {
  container_name     = "${var.name}-container"
  log_stream_prefix  = replace(var.name, " ", "-")
  enable_alb         = var.listener_arn != null && var.listener_arn != ""
  enable_cd          = var.enable_codedeploy && local.enable_alb
}

resource "aws_lb_target_group" "blue" {
  count    = local.enable_alb ? 1 : 0
  name     = substr("${var.name}-blue", 0, 32)
  port     = var.service_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, { Name = "${var.name}-tg-blue" })
}

resource "aws_lb_target_group" "green" {
  count = local.enable_cd ? 1 : 0

  name     = substr("${var.name}-green", 0, 32)
  port     = var.service_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, { Name = "${var.name}-tg-green" })
}

resource "aws_lb_listener_rule" "this" {
  count        = local.enable_alb ? 1 : 0
  listener_arn = var.listener_arn
  priority     = var.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue[0].arn
  }

  condition {
    path_pattern {
      values = var.path_patterns
    }
  }

  condition {
    host_header {
      values = var.host_headers
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_iam_role" "task_execution" {
  count = var.execution_role_arn == null ? 1 : 0

  name = "${var.name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  count      = var.execution_role_arn == null ? 1 : 0
  role       = aws_iam_role.task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  count = var.task_role_arn == null ? 1 : 0

  name = "${var.name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "task_inline" {
  count = var.task_role_arn == null ? 1 : 0

  name = "${var.name}-task-inline"
  role = aws_iam_role.task[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(var.task_additional_policy_statements, [
      {
        Sid    = "AllowLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [local.log_group_arn]
      },
      {
        Sid    = "AllowSecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secret_arns
      },
      {
        Sid    = "AllowSQS"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = var.sqs_queue_arns
      },
      {
        Sid    = "AllowS3List"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = var.s3_bucket_arns
      },
      {
        Sid    = "AllowS3Objects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [for bucket in var.s3_bucket_arns : "${bucket}/*"]
      }
    ])
  })
}

resource "aws_cloudwatch_log_group" "default" {
  count = var.create_log_group ? 1 : 0

  name              = var.log_group_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn

  tags = var.tags
}

locals {
  execution_role_arn = coalesce(var.execution_role_arn, try(aws_iam_role.task_execution[0].arn, null))
  task_role_arn      = coalesce(var.task_role_arn, try(aws_iam_role.task[0].arn, null))
  target_group_arn   = local.enable_alb ? aws_lb_target_group.blue[0].arn : null
  log_group_arn      = coalesce(var.log_group_arn, try(aws_cloudwatch_log_group.default[0].arn, null))
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  cpu                      = var.cpu
  memory                   = var.memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = local.execution_role_arn
  task_role_arn            = local.task_role_arn

  container_definitions = jsonencode([
    {
      name  = local.container_name
      image = var.container_image
      cpu   = var.cpu
      memory = var.memory
      essential = true
      portMappings = local.enable_alb ? [{
        containerPort = var.service_port
        hostPort      = var.service_port
        protocol      = "tcp"
      }] : []
      environment = [for k, v in var.environment : {
        name  = k
        value = v
      }]
      secrets = [for s in var.secrets : {
        name      = s.name
        valueFrom = s.value_from
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = local.log_stream_prefix
        }
      }
      healthCheck = var.container_health_check
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = local.enable_alb ? [local.target_group_arn] : []
    content {
      target_group_arn = load_balancer.value
      container_name   = local.container_name
      container_port   = var.service_port
    }
  }

  deployment_controller {
    type = local.enable_cd ? "CODE_DEPLOY" : "ECS"
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = var.tags
}

resource "aws_appautoscaling_target" "service" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_service.this.cluster}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service.resource_id
  scalable_dimension = aws_appautoscaling_target.service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscale_cpu_target
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "queue_depth" {
  count              = var.sqs_queue_metric != null ? 1 : 0
  name               = "${var.name}-queue"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service.resource_id
  scalable_dimension = aws_appautoscaling_target.service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service.service_namespace

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = var.sqs_queue_metric.metric_name
      namespace   = var.sqs_queue_metric.namespace
      statistic   = var.sqs_queue_metric.statistic
      unit        = var.sqs_queue_metric.unit
      dimensions  = var.sqs_queue_metric.dimensions
    }
    target_value       = var.sqs_queue_metric.target_value
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
  }
}

resource "aws_codedeploy_app" "ecs" {
  count = local.enable_cd ? 1 : 0
  name  = "${var.name}-codedeploy"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "ecs" {
  count                  = local.enable_cd ? 1 : 0
  app_name               = aws_codedeploy_app.ecs[0].name
  deployment_group_name  = "${var.name}-dg"
  service_role_arn       = var.codedeploy_role_arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  ecs_service {
    cluster_name = var.cluster_name
    service_name = aws_ecs_service.this.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.listener_arn]
      }
      test_traffic_route {
        listener_arns = [var.listener_arn]
      }
      target_group {
        name = aws_lb_target_group.blue[0].name
      }
      target_group {
        name = aws_lb_target_group.green[0].name
      }
    }
  }

  alarm_configuration {
    enabled = var.codedeploy_alarm_configuration.enabled
    alarms  = var.codedeploy_alarm_configuration.alarm_names
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }
}
