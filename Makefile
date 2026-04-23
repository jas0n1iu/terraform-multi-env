# Makefile 用于简化 Terraform 操作

.PHONY: help init-dev init-staging init-prod plan-dev plan-staging plan-prod apply-dev apply-staging apply-prod destroy-dev destroy-staging destroy-prod fmt validate

help:
	@echo "可用命令："
	@echo "  make init-dev       - 初始化 dev 环境"
	@echo "  make init-staging   - 初始化 staging 环境"
	@echo "  make init-prod      - 初始化 prod 环境"
	@echo "  make plan-dev       - 查看 dev 环境变更计划"
	@echo "  make plan-staging   - 查看 staging 环境变更计划"
	@echo "  make plan-prod      - 查看 prod 环境变更计划"
	@echo "  make apply-dev      - 应用 dev 环境配置"
	@echo "  make apply-staging  - 应用 staging 环境配置"
	@echo "  make apply-prod     - 应用 prod 环境配置"
	@echo "  make destroy-dev    - 销毁 dev 环境资源"
	@echo "  make destroy-staging- 销毁 staging 环境资源"
	@echo "  make destroy-prod   - 销毁 prod 环境资源"
	@echo "  make fmt            - 格式化所有 Terraform 文件"
	@echo "  make validate       - 验证所有环境配置"

# Dev 环境
init-dev:
	cd environments/dev && terraform init

plan-dev:
	cd environments/dev && terraform plan

apply-dev:
	cd environments/dev && terraform apply

destroy-dev:
	cd environments/dev && terraform destroy

# Staging 环境
init-staging:
	cd environments/staging && terraform init

plan-staging:
	cd environments/staging && terraform plan

apply-staging:
	cd environments/staging && terraform apply

destroy-staging:
	cd environments/staging && terraform destroy

# Production 环境
init-prod:
	cd environments/prod && terraform init

plan-prod:
	cd environments/prod && terraform plan

apply-prod:
	cd environments/prod && terraform apply -auto-approve=false

destroy-prod:
	@echo "⚠️  警告：你正在尝试销毁生产环境！"
	@echo "请输入 'yes' 确认："
	@read confirm && [ "$$confirm" = "yes" ] && cd environments/prod && terraform destroy || echo "已取消"

# 通用命令
fmt:
	terraform fmt -recursive

validate:
	@echo "验证 dev 环境..."
	@cd environments/dev && terraform validate
	@echo "验证 staging 环境..."
	@cd environments/staging && terraform validate
	@echo "验证 prod 环境..."
	@cd environments/prod && terraform validate
	@echo "✅ 所有环境配置验证通过"
