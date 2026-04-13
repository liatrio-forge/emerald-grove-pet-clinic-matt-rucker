locals {
  name_prefix    = "${var.project}-${var.environment}"
  container_name = "${var.project}-app"
}

data "aws_region" "current" {}

# --- ECS Cluster ---

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${local.name_prefix}-cluster" }
}

# --- CloudWatch Logs ---

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 14

  tags = { Name = "${local.name_prefix}-logs" }
}

# --- IAM: Task Execution Role ---

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${local.name_prefix}-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = { Name = "${local.name_prefix}-task-execution" }
}

resource "aws_iam_role_policy_attachment" "task_execution_base" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "secrets_access" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_password_secret_arn, var.anthropic_api_key_secret_arn]
  }
}

resource "aws_iam_role_policy" "task_execution_secrets" {
  name   = "${local.name_prefix}-secrets-access"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.secrets_access.json
}

# --- IAM: Task Role ---

resource "aws_iam_role" "task" {
  name               = "${local.name_prefix}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = { Name = "${local.name_prefix}-task" }
}

# APS RemoteWrite permission for ADOT sidecar (only when AMP endpoint is configured)

resource "aws_iam_role_policy" "task_amp_write" {
  count = var.enable_adot_sidecar ? 1 : 0

  name   = "${local.name_prefix}-amp-remote-write"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.amp_write[0].json
}

data "aws_iam_policy_document" "amp_write" {
  count = var.enable_adot_sidecar ? 1 : 0

  statement {
    actions   = ["aps:RemoteWrite"]
    resources = ["*"]
  }
}

# --- Task Definition ---

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name_prefix}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode(concat(
    [
      {
        name  = local.container_name
        image = var.container_image

        portMappings = [
          {
            containerPort = var.container_port
            protocol      = "tcp"
          }
        ]

        environment = [
          { name = "SPRING_PROFILES_ACTIVE", value = "postgres" },
          { name = "POSTGRES_URL", value = "jdbc:postgresql://${var.db_endpoint}/${var.db_name}" },
          { name = "POSTGRES_USER", value = var.db_username },
        ]

        secrets = [
          { name = "POSTGRES_PASS", valueFrom = var.db_password_secret_arn },
          { name = "ANTHROPIC_API_KEY", valueFrom = var.anthropic_api_key_secret_arn },
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.app.name
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "ecs"
          }
        }

        essential = true
      }
    ],
    var.enable_adot_sidecar ? [
      {
        name      = "adot-collector"
        image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
        essential = false
        memory    = 256

        environment = [
          {
            name = "AOT_CONFIG_CONTENT"
            value = yamlencode({
              extensions = {
                sigv4auth = {
                  region = data.aws_region.current.name
                }
              }
              receivers = {
                prometheus = {
                  config = {
                    scrape_configs = [
                      {
                        job_name        = "spring-boot"
                        scrape_interval = "15s"
                        static_configs = [
                          { targets = ["localhost:${var.container_port}"] }
                        ]
                        metrics_path = "/actuator/prometheus"
                      }
                    ]
                  }
                }
              }
              exporters = {
                prometheusremotewrite = {
                  endpoint = var.amp_remote_write_endpoint
                  auth = {
                    authenticator = "sigv4auth"
                  }
                }
              }
              service = {
                extensions = ["sigv4auth"]
                pipelines = {
                  metrics = {
                    receivers = ["prometheus"]
                    exporters = ["prometheusremotewrite"]
                  }
                }
              }
            })
          }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.app.name
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "adot"
          }
        }
      }
    ] : []
  ))

  tags = { Name = "${local.name_prefix}-task" }
}

# --- ECS Service ---

resource "aws_ecs_service" "app" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  health_check_grace_period_seconds = 60

  tags = { Name = "${local.name_prefix}-service" }
}
