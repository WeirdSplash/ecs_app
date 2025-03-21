output "ecs_cluster_name" {
  value = aws_ecs_cluster.app_cluster.name
}
output "ecs_service_name" {
  value = aws_ecs_service.app_cluster.name
}


output "ecs_service_id" {
  description = "ID del servicio ECS"
  value       = aws_ecs_service.app_service.id
}

output "load_balancer_dns" {
  description = "URL del Load Balancer"
  value       = aws_lb.app_lb.dns_name
}

output "task_definition_arn" {
  description = "ARN de la definición de tarea de ECS"
  value       = aws_ecs_task_definition.app_task.arn
}

output "target_group_arn" {
  description = "ARN del Target Group del ALB"
  value       = aws_lb_target_group.app_tg.arn
}
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}
output "security_group_id" {
  value = aws_security_group.ecs_sg.id
}
output "ec2_key_name" {
  value = aws_key_pair.ecs_key.key_name
}
output "ecr_image_url" {
  value = aws_ecr_repository.app_repo.repository_url
}
