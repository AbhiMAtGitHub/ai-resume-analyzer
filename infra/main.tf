terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "resume-analyzer-tfstate-245595379715"
    key            = "infra/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}


# Frontend Global Config
module "frontend" {
  source = "./"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}


