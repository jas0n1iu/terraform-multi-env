# Staging 环境变量
variable "environment" {
  description = "环境名称"
  type        = string
  default     = "staging"
}

variable "region" {
  description = "AWS 区域"
  type        = string
}

variable "instance_type" {
  description = "EC2 实例类型"
  type        = string
}

variable "instance_count" {
  description = "实例数量"
  type        = number
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
