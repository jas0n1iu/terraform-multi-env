# 应用模块变量定义
variable "environment" {
  description = "环境名称 (dev/staging/prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 实例类型"
  type        = string
}

variable "instance_count" {
  description = "实例数量"
  type        = number
  default     = 1
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "子网 ID"
  type        = string
}

variable "common_tags" {
  description = "通用标签"
  type        = map(string)
  default     = {}
}
