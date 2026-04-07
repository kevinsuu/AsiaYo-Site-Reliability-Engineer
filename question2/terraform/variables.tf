variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "cluster_name" {
  description = "EKS Cluster 名稱"
  type        = string
  default     = "asiayo-cluster"
}

variable "cluster_version" {
  description = "Kubernetes 版本"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "部署環境"
  type        = string
  default     = "production"
}
