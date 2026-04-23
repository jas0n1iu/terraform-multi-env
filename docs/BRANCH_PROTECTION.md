# GitHub 分支保护规则配置

为了确保 GitOps 工作流的安全性，需要配置 GitHub 分支保护规则。

## 🔒 配置步骤

### 1. 进入仓库设置

```
GitHub 仓库 → Settings → Branches → Add branch protection rule
```

### 2. 配置 main 分支保护

**Branch name pattern**: `main`

#### 必须启用的规则：

- ✅ **Require a pull request before merging**
  - ✅ Require approvals: 1（至少 1 人审批）
  - ✅ Dismiss stale pull request approvals when new commits are pushed
  - ✅ Require review from Code Owners（如果有 CODEOWNERS 文件）

- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - 必须通过的检查：
    - `Terraform Validate / validate`
    - `Terraform Plan / plan-dev`
    - `Terraform Plan / plan-staging`
    - `Terraform Plan / plan-prod`（如果修改了 prod）

- ✅ **Require conversation resolution before merging**
  - 所有评论必须解决才能合并

- ✅ **Require signed commits**（推荐）
  - 要求提交签名，增强安全性

- ✅ **Require linear history**（推荐）
  - 保持清晰的提交历史

- ✅ **Include administrators**
  - 管理员也必须遵守这些规则

- ✅ **Restrict who can push to matching branches**
  - 只允许特定团队或人员直接推送
  - 或者完全禁止直接推送（推荐）

- ✅ **Allow force pushes**: ❌ 禁用
- ✅ **Allow deletions**: ❌ 禁用

## 📋 推荐的 CODEOWNERS 文件

创建 `.github/CODEOWNERS` 文件：

```
# 全局所有者
* @your-team/platform-team

# 生产环境需要额外审批
/environments/prod/ @your-team/senior-engineers @your-team/platform-lead

# 模块变更需要架构师审批
/modules/ @your-team/architects

# CI/CD 配置需要 DevOps 审批
/.github/workflows/ @your-team/devops
```

## 🔐 环境保护规则

### Dev 环境
```
Settings → Environments → dev
- ❌ Required reviewers: 无
- ✅ Wait timer: 0 minutes
- ✅ Deployment branches: All branches
```

### Staging 环境
```
Settings → Environments → staging
- ✅ Required reviewers: 1 人
- ✅ Wait timer: 0 minutes
- ✅ Deployment branches: main only
- ✅ Reviewers: @your-team/qa-team
```

### Production 环境
```
Settings → Environments → production
- ✅ Required reviewers: 2 人
- ✅ Wait timer: 5 minutes（冷静期）
- ✅ Deployment branches: main only
- ✅ Reviewers: @your-team/senior-engineers
- ✅ Environment secrets:
    - AWS_ACCESS_KEY_ID_PROD
    - AWS_SECRET_ACCESS_KEY_PROD
```

## 🚦 正确的工作流程

### ❌ 错误做法（不安全）
```bash
# 直接推送到 main（绕过审查）
git checkout main
git add .
git commit -m "changes"
git push origin main  # ❌ 会触发自动部署！
```

### ✅ 正确做法（安全）
```bash
# 1. 创建功能分支
git checkout -b feature/add-instance

# 2. 修改代码
vim environments/dev/terraform.tfvars

# 3. 提交到功能分支
git add .
git commit -m "feat: add new instance"
git push origin feature/add-instance

# 4. 在 GitHub 创建 PR
# 5. 自动触发 terraform-plan.yml
# 6. 团队审查 Plan 结果
# 7. 审批通过后合并
# 8. 自动触发 terraform-apply.yml
```

## 🛡️ 安全检查清单

在合并 PR 前，确保：

- [ ] Terraform Plan 输出已审查
- [ ] 没有意外的资源删除
- [ ] 没有敏感信息泄露
- [ ] 所有自动化测试通过
- [ ] 至少 1 人（生产环境 2 人）审批
- [ ] 所有评论已解决
- [ ] 在合适的时间窗口部署

## 🚨 紧急情况处理

如果需要紧急修复生产问题：

### 方法 1：快速 PR（推荐）
```bash
git checkout -b hotfix/critical-fix
# 修复问题
git commit -m "hotfix: critical production fix"
git push origin hotfix/critical-fix
# 创建 PR，标记为 urgent，快速审批
```

### 方法 2：手动触发（需要权限）
```bash
# 在 GitHub Actions 页面
# 选择 "Terraform Apply" workflow
# 点击 "Run workflow"
# 选择环境和分支
```

### 方法 3：临时禁用保护（最后手段）
```
Settings → Branches → Edit protection rule
临时禁用 → 推送修复 → 立即重新启用
```

## 📊 监控和审计

### 启用审计日志
```
Settings → Security → Audit log
```

### 监控指标
- PR 平均审批时间
- 部署频率
- 失败率
- 回滚次数

### 定期审查
- 每月审查分支保护规则
- 每季度审查访问权限
- 每年审查安全策略

## 🔗 相关文档

- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
