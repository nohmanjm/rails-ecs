terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }


  backend "s3" {

    bucket         = "devops-rails-state-bucket-2025-nohman" 
    key            = "rails-ecs/terraform.tfstate"
    region         = "eu-central-1" 
    dynamodb_table = "devops-lock-table" 
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}


# Test For CI/CD before interview - final test