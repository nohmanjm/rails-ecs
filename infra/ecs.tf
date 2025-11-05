
# 1. ECS Cluster
resource "aws_ecs_cluster" "rails_ecs_cluster" {
  name = "${var.project_name}-cluster"
}

# 2. IAM Roles and Policies


resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_policy" "ssm_read_policy" {
  name        = "${var.project_name}-ssm-read-policy"
  description = "Allows ECS Tasks to read SSM SecureStrings"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ssm_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ssm_read_policy.arn
}


resource "aws_ecs_task_definition" "rails_ecs_task_definition" {
  family                   = "${var.project_name}-task-definition"
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

 
  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-container"

      image     = "${aws_ecr_repository.rails_ecs_repo.repository_url}:${var.image_tag}"
      cpu       = var.cpu
      memory    = var.memory
      essential = true
      portMappings = [
        {
          containerPort = var.container_port # 3000
          hostPort      = var.container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-task-definition"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      environment = [

        { name = "PORT", value = tostring(var.container_port) } 
      ]
      secrets = [
        # Pulling environment variables/secrets from SSM Parameter Store
        { name = "RAILS_ENV", valueFrom = aws_ssm_parameter.rails_env.arn },
        { name = "SECRET_KEY_BASE", valueFrom = aws_ssm_parameter.secret_key_base.arn },
        { name = "RAILS_MASTER_KEY", valueFrom = aws_ssm_parameter.rails_master_key.arn }
      ]
      healthCheck = {
        command  = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
        interval = 30
        timeout  = 5
        retries  = 3
      }
    }
  ])
}

# 4. ECS Service (Keeps the container running and links it to the ALB)
resource "aws_ecs_service" "rails_ecs_service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.rails_ecs_cluster.id
  task_definition = aws_ecs_task_definition.rails_ecs_task_definition.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = aws_subnet.public.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rails_ecs_tg.arn
    container_name   = "${var.project_name}-container"
    container_port   = var.container_port
  }
  

  depends_on = [
    aws_lb_listener.http_listener,
    aws_iam_role_policy_attachment.ecs_task_execution_role_attach,
    aws_iam_role_policy_attachment.ecs_ssm_attach
  ]
}


data "aws_caller_identity" "current" {}
