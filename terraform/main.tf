provider "aws" {
  region = var.aws_region
}

# 1️⃣ Crear el Cluster ECS
resource "aws_ecs_cluster" "app_cluster" {
  name = "my-ecs-cluster"

  capacity_providers = ["EC2CapacityProvider"]

  default_capacity_provider_strategy {
    capacity_provider = "EC2CapacityProvider"
    weight           = 1
  }
}

# 2️⃣ Configurar la plantilla de lanzamiento para EC2
resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "ecs-template-"
  image_id      = "ami-0c55b159cbfafe1f0" # AMI de Amazon Linux 2 con soporte para ECS
  instance_type = "t3.micro"
  key_name      = var.ec2_key_name
  vpc_security_group_ids = [var.security_group_id]

  user_data = base64encode(<<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.app_cluster.name}" >> /etc/ecs/ecs.config
EOF
  )
}

# 3️⃣ Grupo de Auto Scaling para EC2
resource "aws_autoscaling_group" "ecs_asg" {
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = 2
  min_size           = 1
  max_size           = 3

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }
}

# 4️⃣ Capacity Provider para ECS con EC2
resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "EC2CapacityProvider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_termination_protection = "DISABLED"
  }
}

# 5️⃣ Definir la Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "app-container",
    image     = var.ecr_image_url,
    cpu       = 256,
    memory    = 512,
    essential = true,
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
  }])
}

# 6️⃣ Crear el servicio ECS en EC2
resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 2

  capacity_provider_strategy {
    capacity_provider = "EC2CapacityProvider"
    weight           = 1
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "app-container"
    container_port   = 8080
  }
}

# 7️⃣ Load Balancer para ECS en EC2
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids
  enable_deletion_protection = false
}

# 8️⃣ Target Group para la app
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"
}

# 9️⃣ Listener del Load Balancer
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
