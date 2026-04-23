# 应用模块输出
output "instance_ids" {
  description = "EC2 实例 ID 列表"
  value       = aws_instance.app[*].id
}

output "instance_public_ips" {
  description = "EC2 实例公网 IP"
  value       = aws_instance.app[*].public_ip
}

output "security_group_id" {
  description = "安全组 ID"
  value       = aws_security_group.app.id
}
