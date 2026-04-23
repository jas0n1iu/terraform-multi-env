#!/bin/bash
# 设置 Terraform State Backend (S3 + DynamoDB)

set -e

# 配置变量
BUCKET_NAME="my-terraform-state-bucket"
DYNAMODB_TABLE="terraform-state-locks"
REGION="us-east-1"

echo "🚀 开始设置 Terraform State Backend..."

# 1. 创建 S3 Bucket
echo "📦 创建 S3 Bucket: $BUCKET_NAME"
aws s3 mb "s3://${BUCKET_NAME}" --region "$REGION" 2>/dev/null || echo "Bucket 已存在"

# 2. 启用版本控制
echo "🔄 启用 S3 版本控制..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# 3. 启用服务器端加密
echo "🔒 启用 S3 加密..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# 4. 阻止公共访问
echo "🛡️  配置 S3 公共访问阻止..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 5. 启用日志记录
echo "📝 启用 S3 访问日志..."
aws s3api put-bucket-logging \
  --bucket "$BUCKET_NAME" \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "'"$BUCKET_NAME"'",
      "TargetPrefix": "logs/"
    }
  }' 2>/dev/null || echo "日志配置跳过"

# 6. 创建 DynamoDB 表
echo "🗄️  创建 DynamoDB 表: $DYNAMODB_TABLE"
aws dynamodb create-table \
  --table-name "$DYNAMODB_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" 2>/dev/null || echo "DynamoDB 表已存在"

# 7. 等待表创建完成
echo "⏳ 等待 DynamoDB 表激活..."
aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION"

# 8. 启用 DynamoDB 时间点恢复
echo "💾 启用 DynamoDB 时间点恢复..."
aws dynamodb update-continuous-backups \
  --table-name "$DYNAMODB_TABLE" \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
  --region "$REGION" 2>/dev/null || echo "时间点恢复已启用"

echo ""
echo "✅ Terraform State Backend 设置完成！"
echo ""
echo "📋 配置信息："
echo "  S3 Bucket: $BUCKET_NAME"
echo "  DynamoDB Table: $DYNAMODB_TABLE"
echo "  Region: $REGION"
echo ""
echo "🔧 请在 backend.tf 中使用以下配置："
echo ""
cat << EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "ENV/terraform.tfstate"  # 替换 ENV 为 dev/staging/prod
    region         = "$REGION"
    encrypt        = true
    dynamodb_table = "$DYNAMODB_TABLE"
  }
}
EOF
echo ""
echo "🎉 现在可以运行 'terraform init' 了！"
