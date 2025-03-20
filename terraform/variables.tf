variable "aws_region" {
  default = "us-east-1"
}

variable "ecr_image_url" {
  description = "URL de la imagen en ECR"
  type        = string
}
