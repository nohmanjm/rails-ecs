# ============================================================
# ALB + Target Group for rails-ecs
# ============================================================

# Public ALB security group (allow HTTP from anywhere)
resource "aws_security_group" "alb" {
  # Use name_prefix so Terraform can create a new SG before destroying the old one
  name_prefix = "${var.project_name}-alb-"
  description = "Allow inbound HTTP to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer (public)
resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = [for s in aws_subnet.public : s.id]
  security_groups    = [aws_security_group.alb.id]

  enable_http2 = true
  idle_timeout = 60
}

# Target Group forwarding to ECS tasks (IP target type)
resource "aws_lb_target_group" "app" {
  # Use a prefix so TF can replace safely without "in use" errors
  name_prefix = "rails-"

  port        = var.container_port # expect 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    matcher             = "200-399" # more forgiving during boot
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 10
  }

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP listener on :80 forwarding to the target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
