# --- Security Groups ---

# 1. ALB Security Group (Public)
resource "aws_security_group" "lb_sg" {
  name        = "alb-security-group"
  description = "Controls access to the ALB"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP traffic on Port 80 (Frontend Access)
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow API traffic on Port 8000 (Frontend -> Backend Access)
  ingress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. ECS Task Security Group (Private-ish)
resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-security-group"
  description = "Allow traffic only from ALB"
  vpc_id      = aws_vpc.main.id

  # Allow Inbound from ALB on Port 3000 (Frontend)
  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.lb_sg.id]
  }

  # Allow Inbound from ALB on Port 8000 (Backend)
  ingress {
    protocol        = "tcp"
    from_port       = 8000
    to_port         = 8000
    security_groups = [aws_security_group.lb_sg.id]
  }

  # Allow tasks to talk to the internet (for ECR pull / Aptitude updates)
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Load Balancer ---
resource "aws_lb" "main" {
  name               = "app-lb"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.lb_sg.id]
  load_balancer_type = "application"
}

# --- Target Groups ---
resource "aws_lb_target_group" "frontend_tg" {
  name        = "frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    port                = "3000"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "backend-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"  # Ensure your app.py has this route!
    port                = "8000"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# --- Listeners ---
resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "8000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}
