terraform {
  backend "s3" {
    bucket         = "my-terraform-state-jk"
    key            = "ecs-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}
