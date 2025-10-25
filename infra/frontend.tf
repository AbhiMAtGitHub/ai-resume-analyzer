# FRONTEND INFRA - ECS Fargate for Streamlit App
data "aws_kms_key" "ai_resume_analyzer_key" {
  key_id = aws_kms_key.project_key.id
}

# CloudWatch Logs (encrypted)
resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/ecs/${var.project_name}-${var.environment}-frontend"
  retention_in_days = 14
  kms_key_id        = data.aws_kms_key.project_kms.arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "frontend_cluster" {
  name = "${var.project_name}-${var.environment}-frontend-cluster"
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Roles
resource "aws_iam_role" "frontend_exec_role" {
  name = "${var.project_name}-${var.environment}-frontend-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "frontend_exec_role_policy" {
  role       = aws_iam_role.frontend_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "frontend_task_role" {
  name = "${var.project_name}-${var.environment}-frontend-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Task Definition
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "${var.project_name}-${var.environment}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.frontend_cpu)
  memory                   = tostring(var.frontend_memory)
  execution_role_arn       = aws_iam_role.frontend_exec_role.arn
  task_role_arn            = aws_iam_role.frontend_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "streamlit"
      image     = "${aws_ecr_repository.frontend_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.frontend_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "API_BASE_URL", value = var.frontend_api_base_url }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

# ECS Service (Fargate with public IP)
resource "aws_ecs_service" "frontend_service" {
  name            = "${var.project_name}-${var.environment}-frontend-svc"
  cluster         = aws_ecs_cluster.frontend_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = var.frontend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.frontend_sg.id]
    assign_public_ip = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

output "frontend_cluster_name" {
  value       = aws_ecs_cluster.frontend_cluster.name
  description = "ECS cluster name"
}

output "frontend_service_name" {
  value       = aws_ecs_service.frontend_service.name
  description = "Frontend ECS service name"
}
