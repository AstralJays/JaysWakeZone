# Stack 2 of 3 — ECS Fargate + ALB (Lab 4)
# Public Docker Hub image — no ECR. Default VPC (no NAT) to keep cost down.
# Destroy promptly — ALB has hourly cost.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = ""
}

variable "name_prefix" {
  type    = string
  default = "jayswakezone"
}

variable "container_image" {
  type    = string
  default = "python:3.9-bullseye"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  boot = file("${path.module}/../../../lab4-containers/boot.sh")
}

resource "aws_cloudwatch_log_group" "lab4" {
  name              = "/ecs/${var.name_prefix}-lab4"
  retention_in_days = 3
}

resource "aws_ecs_cluster" "lab4" {
  name = "${var.name_prefix}-lab4"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Project = "JaysWakeZone"
    Stack   = "lab4-containers"
    Lab     = "4"
  }
}

resource "aws_iam_role" "ecs_execution" {
  name = "${var.name_prefix}-lab4-ecs-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "lab4" {
  family                   = "${var.name_prefix}-lab4"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name      = "jwz"
    image     = var.container_image
    essential = true
    command   = ["bash", "-c", local.boot]
    environment = [
      { name = "JWZ_LAB", value = "4-containers" },
      { name = "PORT", value = "8080" },
    ]
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.lab4.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "jwz"
      }
    }
  }])
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-lab4-alb-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "tasks" {
  name_prefix = "${var.name_prefix}-lab4-task-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "lab4" {
  name               = "${var.name_prefix}-lab4"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
  idle_timeout       = 60

  tags = {
    Project = "JaysWakeZone"
    Lab     = "4"
  }
}

resource "aws_lb_target_group" "lab4" {
  name        = "${var.name_prefix}-lab4"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "lab4" {
  load_balancer_arn = aws_lb.lab4.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab4.arn
  }
}

resource "aws_ecs_service" "lab4" {
  name            = "${var.name_prefix}-lab4"
  cluster         = aws_ecs_cluster.lab4.id
  task_definition = aws_ecs_task_definition.lab4.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lab4.arn
    container_name   = "jwz"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.lab4]
}

output "lab4_url" {
  description = "ECS service via ALB — install tracer yourself"
  value       = "http://${aws_lb.lab4.dns_name}"
}

output "lab4_cluster" {
  value = aws_ecs_cluster.lab4.name
}
