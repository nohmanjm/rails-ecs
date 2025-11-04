terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state backend with S3 and DynamoDB locking
  backend "s3" {
    # REPLACE these with the exact names you created via CLI:
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
