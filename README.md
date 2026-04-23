# Terraform 多环境项目

这是一个完整的 Terraform 多环境隔离项目示例，支持 dev、staging 和 prod 三个环境。

## 项目结构

```
.
├── modules/                    # 可复用的 Terraform 模块
│   └── app/                   # 应用模块
│       ├── main.tf            # 主要资源定义
│       ├── variables.tf       # 变量定义
│       └── outputs.tf         # 输出定义
├── environments/              # 环境配置
│   ├── dev/                   # 开发环境
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── backend.tf
│   │   └── outputs.tf
│   ├── staging/               # 预发布环境
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── backend.tf
│   │   └── outputs.tf
│   └── prod/                  # 生产环境
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── backend.tf
│       └── outputs.tf
└── README.md
```

## 环境配置对比

| 环境 | 实例类型 | 实例数量 | 用途 |
|------|---------|---------|------|
| dev | t3.micro | 1 | 开发测试 |
| staging | t3.small | 2 | 预发布验证 |
| prod | t3.large | 3 | 生产环境 |

## 前置准备

### 1. 安装 Terraform

```bash
# macOS
brew install terraform

# 验证安装
terraform version
```

### 2. 配置 AWS 凭证

```bash
# 配置 AWS CLI
aws configure

# 或设置环境变量
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 3. 创建 S3 Bucket 和 DynamoDB 表（用于状态管理）

```bash
# 使用自动化脚本
chmod +x scripts/setup-state-backend.sh
./scripts/setup-state-backend.sh

# 或手动创建
aws s3 mb s3://my-terraform-state-bucket --region us-east-1
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled
aws dynamodb create-table \
  --table-name terraform-state-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 4. 更新配置文件

在每个环境的 `terraform.tfvars` 和 `backend.tf` 中：
- 替换 S3 bucket 名称
- 替换 VPC ID 和 Subnet ID
- 根据需要调整 AMI ID

## 使用方法

### 部署 Dev 环境

```bash
# 进入 dev 环境目录
cd environments/dev

# 初始化 Terraform
terraform init

# 查看执行计划
terraform plan

# 应用配置
terraform apply

# 查看输出
terraform output
```

### 部署 Staging 环境

```bash
cd environments/staging
terraform init
terraform plan
terraform apply
```

### 部署 Production 环境

```bash
cd environments/prod
terraform init
terraform plan
terraform apply
```

### 销毁资源

```bash
# 在对应环境目录下
terraform destroy
```

## 最佳实践

### 1. 状态文件隔离
- 每个环境使用独立的 S3 key 存储状态文件
- 启用状态文件加密和版本控制
- 使用 DynamoDB 进行状态锁定，防止并发修改

### 2. 访问控制
```bash
# 为不同环境创建不同的 IAM 角色
# Dev 环境使用 dev-terraform-role
# Prod 环境使用 prod-terraform-role
```

### 3. 变量管理
- 敏感信息使用环境变量或 AWS Secrets Manager
- 不要将 `terraform.tfvars` 中的敏感信息提交到版本控制

### 4. 代码审查流程
```bash
# Dev 环境：开发人员可以直接部署
# Staging 环境：需要 Team Lead 审批
# Prod 环境：需要多人审批和变更窗口
```

### 5. 使用 Terraform Cloud/Enterprise（可选）
- 提供更好的协作和审批流程
- 自动化 CI/CD 集成
- 更安全的凭证管理

## 常用命令

```bash
# 格式化代码
terraform fmt -recursive

# 验证配置
terraform validate

# 查看当前状态
terraform show

# 列出所有资源
terraform state list

# 导入现有资源
terraform import module.app.aws_instance.app[0] i-1234567890abcdef0

# 刷新状态
terraform refresh

# 查看特定资源
terraform state show module.app.aws_instance.app[0]
```

## 故障排查

### 状态锁定问题
```bash
# 如果状态被锁定，可以强制解锁（谨慎使用）
terraform force-unlock <lock-id>
```

### Backend 初始化问题
```bash
# 重新配置 backend
terraform init -reconfigure

# 迁移状态到新 backend
terraform init -migrate-state
```

## 扩展建议

1. 添加更多模块（RDS、ELB、CloudFront 等）
2. 集成 CI/CD 流水线（GitHub Actions、GitLab CI）
3. 使用 Terragrunt 简化配置管理
4. 添加自动化测试（Terratest）
5. 实现蓝绿部署或金丝雀发布

## GitOps 工作流

本项目支持完整的 GitOps 工作流程：

### 自动化 CI/CD
- **PR 时自动执行** `terraform plan`
- **合并后自动部署** 到各环境
- **每日自动检测** 配置漂移

### GitHub Actions 工作流
- `.github/workflows/terraform-plan.yml` - PR 时执行 plan
- `.github/workflows/terraform-apply.yml` - 合并后自动部署
- `.github/workflows/terraform-drift-detection.yml` - 定期漂移检测

详细的 GitOps 工作流程请查看：
- [GitOps 工作流文档](docs/GITOPS_WORKFLOW.md)
- [分支保护规则配置](docs/BRANCH_PROTECTION.md)

## State 管理

### ❌ 不要通过 Git 管理 State
- State 文件包含敏感信息
- 会导致并发冲突
- 无法提供锁机制

### ✅ 使用远程 Backend (S3 + DynamoDB)
- **S3**：存储 state 文件，启用版本控制和加密
- **DynamoDB**：提供状态锁，防止并发修改
- **隔离**：每个环境独立的 state 文件

```
s3://my-terraform-state-bucket/
├── dev/terraform.tfstate
├── staging/terraform.tfstate
└── prod/terraform.tfstate
```

## 注意事项

⚠️ 生产环境操作前务必：
- 仔细检查 `terraform plan` 输出
- 在非生产环境先验证
- 做好备份和回滚计划
- 在维护窗口期执行变更
- 通知相关团队成员

⚠️ State 文件安全：
- **永远不要**将 `*.tfstate` 提交到 Git
- 使用远程 backend 存储
- 启用加密和版本控制
- 定期备份 state 文件
