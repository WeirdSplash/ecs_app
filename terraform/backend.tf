terraform {
  backend "s3" {
    bucket         = "terraform-state-ecs-ejemplo"
    key            = "ecs-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}
