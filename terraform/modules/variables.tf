variable "aws_region" {
  description = "Región donde se desplegará la infraestructura"
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID de la VPC donde se ejecutará el ECS"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de subnets para los servicios de ECS"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del security group para la instancia ECS"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Nombre del clúster ECS"
  default     = "my-ecs-cluster"
}

variable "container_port" {
  description = "Puerto expuesto por el contenedor"
  default     = 8080
}

variable "desired_task_count" {
  description = "Número deseado de tareas (tasks) para el servicio ECS"
  default     = 2
}

variable "tags" {
  description = "Etiquetas estándar para los recursos"
  type        = map(string)
  default     = {
    Environment = "Production"
    Project     = "MyProject"
  }
}
