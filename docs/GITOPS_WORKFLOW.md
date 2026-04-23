# Terraform GitOps 工作流程

## 概述

本项目采用 GitOps 方式管理基础设施，所有变更通过 Git 进行版本控制和审批。

## 核心原则

1. **Git 是唯一的真实来源**：所有基础设施代码存储在 Git 中
2. **声明式配置**：使用 Terraform 声明期望的基础设施状态
3. **自动化部署**：通过 CI/CD 自动执行 plan 和 apply
4. **审批流程**：生产环境变更需要人工审批
5. **可追溯性**：所有变更都有 Git 提交记录

## State 管理策略

### ❌ 不要做的事

- **不要**将 `*.tfstate` 文件提交到 Git
- **不要**在本地直接操作生产环境
- **不要**手动修改云资源（绕过 Terraform）
- **不要**共享 AWS 凭证

### ✅ 应该做的事

- **使用远程 Backend**：S3 + DynamoDB
- **启用状态加密**：`encrypt = true`
- **启用版本控制**：S3 bucket versioning
- **使用状态锁**：DynamoDB 防止并发修改
- **分离环境 State**：每个环境独立的 state 文件

### State 文件结构

```
s3://my-terraform-state-bucket/
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

## GitOps 工作流程

### 1. 开发流程

```bash
# 1. 创建功能分支
git checkout -b feature/add-new-instance

# 2. 修改 Terraform 配置
vim environments/dev/terraform.tfvars

# 3. 本地验证（可选）
cd environments/dev
terraform init
terraform plan

# 4. 提交变更
git add .
git commit -m "feat: add new instance to dev"
git push origin feature/add-new-instance
```

### 2. Pull Request 流程

创建 PR 后，自动触发：

```
┌─────────────────────────────────────┐
│  开发者创建 PR                        │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  GitHub Actions 自动执行              │
│  ✓ terraform fmt -check             │
│  ✓ terraform validate               │
│  ✓ terraform plan                   │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  Plan 结果自动评论到 PR               │
│  团队成员审查变更                     │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  审批通过后合并到 main                │
└─────────────────────────────────────┘
```

### 3. 自动部署流程

合并到 main 后：

```
┌─────────────────────────────────────┐
│  PR 合并到 main 分支                  │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  自动部署 Dev 环境                    │
│  terraform apply -auto-approve      │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  自动部署 Staging 环境                │
│  (需要 Dev 成功)                      │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  等待人工审批                         │
│  (GitHub Environment Protection)    │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  部署 Production 环境                 │
│  terraform apply -auto-approve      │
└─────────────────────────────────────┘
```

## 环境保护规则

### Dev 环境
- 自动部署
- 无需审批
- 开发人员可直接合并

### Staging 环境
- 自动部署
- 需要 1 人审批
- Team Lead 可审批

### Production 环境
- 需要 2 人审批
- 只能在工作时间部署
- 需要变更窗口
- 自动创建部署记录

## 配置 GitHub Environments

在 GitHub 仓库设置中配置：

### 1. 创建 Environments

```
Settings → Environments → New environment
```

创建三个环境：
- `dev`
- `staging`
- `production`

### 2. 配置 Production 保护规则

```yaml
Environment: production
├── Required reviewers: 2
├── Wait timer: 0 minutes
├── Deployment branches: main only
└── Environment secrets:
    ├── AWS_ACCESS_KEY_ID_PROD
    └── AWS_SECRET_ACCESS_KEY_PROD
```

## 配置漂移检测

每天自动检测配置漂移：

```yaml
# .github/workflows/terraform-drift-detection.yml
on:
  schedule:
    - cron: '0 9 * * *'  # 每天早上 9 点
```

如果检测到漂移：
1. 自动创建 GitHub Issue
2. 发送通知到 Slack/Email
3. 标记受影响的环境

## 回滚策略

### 方法 1：Git Revert

```bash
# 回滚最近的提交
git revert HEAD
git push origin main

# 自动触发部署，恢复到之前的状态
```

### 方法 2：手动回滚（紧急情况）

```bash
# 1. 找到之前的 commit
git log --oneline

# 2. 检出之前的版本
git checkout <commit-hash> environments/prod/

# 3. 提交回滚
git commit -m "rollback: revert prod to previous state"
git push origin main
```

### 方法 3：使用 Terraform State

```bash
# 查看历史状态
aws s3 ls s3://my-terraform-state-bucket/prod/ --recursive

# 恢复到之前的状态文件
aws s3 cp s3://my-terraform-state-bucket/prod/terraform.tfstate?versionId=xxx \
  s3://my-terraform-state-bucket/prod/terraform.tfstate
```

## 最佳实践

### 1. 小步快跑
- 每次 PR 只改一个环境或功能
- 避免大规模变更

### 2. 先测试后生产
- Dev → Staging → Production
- 每个环境验证后再进入下一个

### 3. 使用 Terraform Modules
- 保持 DRY 原则
- 模块版本化管理

### 4. 代码审查清单
- [ ] Terraform 格式正确
- [ ] Plan 输出符合预期
- [ ] 没有意外的资源删除
- [ ] 敏感信息已脱敏
- [ ] 文档已更新

### 5. 监控和告警
- 部署后验证资源状态
- 设置 CloudWatch 告警
- 定期检查配置漂移

## 故障处理

### State 锁定问题

```bash
# 查看锁定信息
aws dynamodb get-item \
  --table-name terraform-state-locks \
  --key '{"LockID":{"S":"my-terraform-state-bucket/prod/terraform.tfstate"}}'

# 强制解锁（谨慎使用）
terraform force-unlock <lock-id>
```

### State 损坏

```bash
# 从 S3 恢复历史版本
aws s3api list-object-versions \
  --bucket my-terraform-state-bucket \
  --prefix prod/terraform.tfstate

# 恢复特定版本
aws s3api get-object \
  --bucket my-terraform-state-bucket \
  --key prod/terraform.tfstate \
  --version-id <version-id> \
  terraform.tfstate.backup
```

## 安全建议

1. **最小权限原则**：CI/CD 使用专用的 IAM 角色
2. **密钥轮换**：定期更新 AWS 凭证
3. **审计日志**：启用 CloudTrail 记录所有 API 调用
4. **加密传输**：使用 HTTPS 和 TLS
5. **定期备份**：State 文件自动备份到多个区域

## 参考资料

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [GitOps Principles](https://www.gitops.tech/)
- [AWS Terraform Backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
