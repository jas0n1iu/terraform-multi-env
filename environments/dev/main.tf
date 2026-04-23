# Dev 环境主配置
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "MyApp"
    }
  }
}

module "app" {
  source = "../../modules/app"
  
  environment    = var.environment
  instance_type  = var.instance_type
  instance_count = var.instance_count
  ami_id         = var.ami_id
  vpc_id         = var.vpc_id
  subnet_id      = var.subnet_id
  
  common_tags = {
    Team = "Development"
    Cost = "Dev"
  }
}
