variable "aws_region" {
  default = "us-east-1"
}

variable "ecr_image_url" {
  description = "URL de la imagen en Amazon ECR"
}

variable "subnet_ids" {
  description = "Lista de subnets en la VPC"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del Security Group para ECS"
}

variable "vpc_id" {
  description = "ID de la VPC"
}

variable "ec2_key_name" {
  description = "Nombre de la clave SSH para acceder a las instancias EC2"
}
