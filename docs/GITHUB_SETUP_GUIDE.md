# GitHub 仓库设置完整指南

本文档提供 GitHub 仓库的完整设置步骤，包括分支保护、环境配置和密钥管理。

## 📋 目录

1. [配置 GitHub Secrets](#1-配置-github-secrets)
2. [配置 GitHub Environments](#2-配置-github-environments)
3. [触发工作流（首次）](#3-触发工作流首次)
4. [配置分支保护规则](#4-配置分支保护规则)
5. [验证配置](#5-验证配置)

---

## 1. 配置 GitHub Secrets

### 1.1 添加 AWS 凭证

```
仓库 → Settings → Secrets and variables → Actions → New repository secret
```

添加以下 secrets：

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `AWS_ACCESS_KEY_ID` | Dev/Staging AWS 访问密钥 | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Dev/Staging AWS 密钥 | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_ACCESS_KEY_ID_PROD` | Production AWS 访问密钥 | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY_PROD` | Production AWS 密钥 | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |

### 1.2 创建专用 IAM 用户（推荐）

```bash
# 为 CI/CD 创建专用 IAM 用户
aws iam create-user --user-name terraform-ci-dev
aws iam create-user --user-name terraform-ci-prod

# 附加必要的权限策略
aws iam attach-user-policy \
  --user-name terraform-ci-dev \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# 创建访问密钥
aws iam create-access-key --user-name terraform-ci-dev
```

---

## 2. 配置 GitHub Environments

### 2.1 创建环境

```
仓库 → Settings → Environments → New environment
```

创建三个环境：`dev`、`staging`、`production`

### 2.2 Dev 环境配置

```
Environment name: dev

Protection rules:
☐ Required reviewers (不勾选)
☐ Wait timer (不勾选)

Deployment branches:
○ All branches (选择此项)
```

### 2.3 Staging 环境配置

```
Environment name: staging

Protection rules:
☑ Required reviewers
  添加审批人: @your-team/qa-team 或具体成员
  Required number of reviewers: 1

☐ Wait timer: 0 minutes

Deployment branches:
○ Selected branches
  添加: main
```

### 2.4 Production 环境配置

```
Environment name: production

Protection rules:
☑ Required reviewers
  添加审批人: @your-team/senior-engineers
  Required number of reviewers: 2

☑ Wait timer: 5 minutes (冷静期)

Deployment branches:
○ Selected branches
  添加: main

Environment secrets:
- AWS_ACCESS_KEY_ID_PROD
- AWS_SECRET_ACCESS_KEY_PROD
```

---

## 3. 触发工作流（首次）

在配置分支保护之前，需要先让工作流运行一次，这样 status checks 才会出现在可选列表中。

### 3.1 创建测试分支

```bash
# 1. 确保在最新的 main 分支
git checkout main
git pull origin main

# 2. 创建测试分支
git checkout -b test/initial-setup

# 3. 做一个小改动（触发工作流）
echo "# Setup Complete" >> SETUP.md
git add SETUP.md
git commit -m "test: trigger initial workflows"

# 4. 推送到 GitHub
git push origin test/initial-setup
```

### 3.2 创建 Pull Request

1. 访问你的 GitHub 仓库
2. 点击 "Pull requests" → "New pull request"
3. Base: `main` ← Compare: `test/initial-setup`
4. 点击 "Create pull request"

### 3.3 观察工作流运行

在 PR 页面，你会看到以下检查开始运行：

```
⏳ 验证 Terraform 配置 — In progress
⏳ Plan Dev 环境 — In progress
⏳ Plan Staging 环境 — In progress
⏳ Plan Production 环境 — In progress
```

等待所有检查完成（可能需要几分钟）：

```
✓ 验证 Terraform 配置 — Passed
✓ Plan Dev 环境 — Passed
✓ Plan Staging 环境 — Passed
✓ Plan Production 环境 — Passed
```

> ⚠️ **注意**：如果某些检查失败（比如 AWS 凭证未配置），这是正常的。我们只需要让它们运行一次即可。

### 3.4 暂时不要合并

先不要合并这个 PR，我们需要先配置分支保护规则。

---

## 4. 配置分支保护规则

现在 status checks 已经运行过了，可以配置分支保护了。

### 4.1 进入分支保护设置

```
仓库 → Settings → Branches → Add branch protection rule
```

### 4.2 基本设置

```
Branch name pattern: main
```

### 4.3 Pull Request 要求

```
☑ Require a pull request before merging
  ☑ Require approvals
    Required number of approvals before merging: 1
  ☑ Dismiss stale pull request approvals when new commits are pushed
  ☑ Require review from Code Owners (如果有 CODEOWNERS 文件)
```

### 4.4 状态检查要求

```
☑ Require status checks to pass before merging
  ☑ Require branches to be up to date before merging
  
  Status checks that are required:
  在搜索框中输入并选择以下检查：
  
  ✓ 验证 Terraform 配置
  ✓ Plan Dev 环境
  ✓ Plan Staging 环境
  ✓ Plan Production 环境
```

**如何搜索：**
1. 在 "Search for status checks" 输入框中输入关键词
2. 从下拉列表中选择对应的检查项
3. 选中后会显示在 "Status checks that are required" 列表中

**如果搜索不到：**
- 确保步骤 3 中的 PR 已经触发了工作流
- 刷新页面重试
- 检查 Actions 标签页确认工作流已运行

### 4.5 其他保护规则

```
☑ Require conversation resolution before merging
  (所有评论必须解决才能合并)

☑ Require signed commits (推荐)
  (要求提交签名)

☑ Require linear history (推荐)
  (禁止 merge commits，只允许 rebase 或 squash)

☑ Include administrators
  (管理员也必须遵守规则)
```

### 4.6 推送限制

```
☐ Do not allow bypassing the above settings
  (不允许绕过以上设置)

Rules applied to everyone including administrators:
☐ Allow force pushes (不勾选 - 禁止强制推送)
☐ Allow deletions (不勾选 - 禁止删除分支)
```

### 4.7 保存规则

点击 **"Create"** 或 **"Save changes"** 按钮

---

## 5. 验证配置

### 5.1 测试分支保护

回到步骤 3 创建的 PR，现在应该看到：

```
✓ 验证 Terraform 配置
✓ Plan Dev 环境
✓ Plan Staging 环境
✓ Plan Production 环境

⚠️ Review required
  At least 1 approving review is required by reviewers with write access.

✓ This branch has no conflicts with the base branch
```

### 5.2 测试直接推送（应该被拒绝）

```bash
# 尝试直接推送到 main（应该失败）
git checkout main
echo "test" >> test.txt
git add test.txt
git commit -m "test: direct push"
git push origin main
```

应该看到错误：

```
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: error: At least 1 approving review is required by reviewers with write access.
To github.com:your-username/your-repo.git
 ! [remote rejected] main -> main (protected branch hook declined)
error: failed to push some refs to 'github.com:your-username/your-repo.git'
```

✅ 这说明分支保护配置成功！

### 5.3 测试正常工作流

```bash
# 1. 撤销刚才的提交
git reset --hard HEAD~1

# 2. 创建功能分支
git checkout -b feature/test-workflow
echo "test" >> test.txt
git add test.txt
git commit -m "feat: test normal workflow"
git push origin feature/test-workflow

# 3. 创建 PR
# 4. 等待检查通过
# 5. 请求审批
# 6. 审批通过后合并
```

---

## 6. 常见问题

### Q1: 找不到 status checks

**A:** 确保工作流至少运行过一次。创建一个测试 PR 触发工作流。

### Q2: 工作流失败

**A:** 检查：
- AWS 凭证是否正确配置
- S3 bucket 和 DynamoDB 表是否已创建
- IAM 权限是否足够

### Q3: 无法推送到 main

**A:** 这是正常的！分支保护生效了。必须通过 PR 流程。

### Q4: 管理员也无法推送

**A:** 如果勾选了 "Include administrators"，管理员也必须遵守规则。这是推荐的安全实践。

### Q5: 如何临时禁用保护

**A:** 
```
Settings → Branches → Edit rule → 临时取消勾选 → Save
完成操作后立即重新启用！
```

---

## 7. 下一步

配置完成后：

1. ✅ 合并测试 PR
2. ✅ 观察自动部署流程
3. ✅ 配置 Slack/Email 通知（可选）
4. ✅ 设置定期漂移检测
5. ✅ 培训团队成员使用新流程

---

## 8. 检查清单

配置完成后，确认以下项目：

- [ ] AWS Secrets 已配置
- [ ] 三个 Environments 已创建
- [ ] Production 环境需要 2 人审批
- [ ] 分支保护规则已启用
- [ ] 4 个 status checks 已添加
- [ ] 直接推送 main 被拒绝（测试通过）
- [ ] PR 工作流正常运行
- [ ] CODEOWNERS 文件已配置
- [ ] 团队成员已了解新流程

---

## 9. 参考资料

- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Terraform GitOps Best Practices](docs/GITOPS_WORKFLOW.md)
