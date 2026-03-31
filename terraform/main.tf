provider "aws" {
  region = "us-east-2"
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

data "aws_ecr_repository" "app" {
  name = "demo"
}

resource "aws_ecs_cluster" "main" {
  name = "my-ecs-cluster"
}

resource "aws_iam_role" "ecs_exec" {
  name = "ecs-execution-role-scratch"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ 
      Action = "sts:AssumeRole", 
      Effect = "Allow", 
      Principal = { Service = "ecs-tasks.amazonaws.com" } 
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach" {
  role       = aws_iam_role.ecs_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/my-app"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "app" {
  family                   = "my-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_exec.arn

  container_definitions = jsonencode([{
    name      = "my-app"
    image     = "${data.aws_ecr_repository.app.repository_url}:latest"
    portMappings = [{ 
      containerPort = 3000
      hostPort      = 3000 
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/my-app"
        "awslogs-region"        = "us-east-2"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg-scratch"
  vpc_id      = data.aws_vpc.default.id

  ingress { 
    from_port   = 3000
    to_port     = 3000
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

resource "aws_ecs_service" "main" {
  name            = "my-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }
}