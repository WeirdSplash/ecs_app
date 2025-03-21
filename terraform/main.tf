provider "aws" {
  region = var.aws_region
}

resource "aws_ecs_cluster" "app_cluster" {
  name = "app-cluster"
}

resource "aws_launch_template" "ecs_launch_template" {
  name_prefix            = "ecs-template-"
  image_id               = "ami-0c55b159cbfafe1f0"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ecs_key.key_name
  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  user_data = base64encode(<<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.app_cluster.name}" >> /etc/ecs/ecs.config
EOF
  )
}

resource "aws_autoscaling_group" "ecs_asg" {
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  desired_capacity    = 2
  min_size            = 1
  max_size            = 3
  health_check_type   = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$${aws_launch_template.ecs_launch_template.latest_version}"
  }
}

resource "aws_ecr_repository" "app_repo" {
  name = "app-repo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

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

resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 2

  capacity_provider_strategy {
    capacity_provider = "EC2CapacityProvider"
    weight            = 1
  }
}

resource "aws_lb" "app_lb" {
  name                       = "app-lb"
  internal                   = false
  security_groups            = [aws_security_group.ecs_sg.id]
  subnets                    = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:REGION:ACCOUNT_ID:certificate/CERTIFICATE_ID"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["TU_IP/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.app_cluster.name}/${aws_ecs_service.app_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_scaling_policy" {
  name               = "ecs-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 50
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
