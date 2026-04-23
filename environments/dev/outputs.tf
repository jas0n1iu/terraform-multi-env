# Dev 环境输出
output "app_instance_ids" {
  description = "应用实例 ID"
  value       = module.app.instance_ids
}

output "app_public_ips" {
  description = "应用实例公网 IP"
  value       = module.app.instance_public_ips
}

output "security_group_id" {
  description = "安全组 ID"
  value       = module.app.security_group_id
}
