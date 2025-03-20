provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "app_cluster" {
  name = "my-ecs-cluster"
}

resource "aws_ecs_task_definition" "app_task" {
  family                = "app-task"
  container_definitions = jsonencode([{
    name      = "app-container",
    image     = "<ECR_IMAGE_URL>",
    cpu       = 256,
    memory    = 512,
    essential = true,
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
  }])
}

resource "aws_ecs_service" "app_service" {
  cluster        = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count  = 2
  launch_type    = "FARGATE"

  network_configuration {
    subnets         = ["<SUBNET_ID>"]
    security_groups = ["<SECURITY_GROUP_ID>"]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "app-container"
    container_port   = 8080
  }
}

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  security_groups    = ["<SECURITY_GROUP_ID>"]
  subnets            = ["<SUBNET_ID>"]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "<VPC_ID>"
}
