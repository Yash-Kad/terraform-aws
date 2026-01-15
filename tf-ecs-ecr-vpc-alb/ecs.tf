resource "aws_ecs_cluster" "main" {
  name = "app-cluster"
}

# --- IAM Role ---
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRoleUnique"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Backend Service ---
resource "aws_ecs_task_definition" "backend" {
  family                   = "backend-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "backend"
    image     = aws_ecr_repository.backend.repository_url
    portMappings = [{ containerPort = 8000, hostPort = 8000 }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.backend.name
        "awslogs-region"        = "ap-south-1" 
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  # Give container 3 minutes to start before ALB checks it
  health_check_grace_period_seconds = 180 

  network_configuration {
    security_groups  = [aws_security_group.ecs_task_sg.id] # Fixed: Use correct SG
    subnets          = aws_subnet.public[*].id
    assign_public_ip = true
  }

  # Fixed: Connect to ALB so port 8000 works
  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = 8000
  }
}

# --- Frontend Service ---
resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = aws_ecr_repository.frontend.repository_url
    portMappings = [{ containerPort = 3000, hostPort = 3000 }]
    environment = [
      # Points to the ALB on Port 8000
      { name = "BACKEND_URL", value = "http://${aws_lb.main.dns_name}:8000/people" } 
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
        "awslogs-region"        = "ap-south-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  health_check_grace_period_seconds = 180

  network_configuration {
    security_groups  = [aws_security_group.ecs_task_sg.id] # Fixed: Use correct SG
    subnets          = aws_subnet.public[*].id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = 3000
  }
}
