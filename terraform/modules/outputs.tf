output "ecs_cluster_name" {
  description = "El nombre del clúster ECS creado"
  value       = aws_ecs_cluster.app_cluster.name
}

output "ecs_service_arn" {
  description = "ARN del servicio ECS"
  value       = aws_ecs_service.app_service.arn
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
