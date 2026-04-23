# Staging 环境 Backend 配置
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"  # 替换为你的 S3 bucket
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
