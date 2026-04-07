# 東京 region，離台灣近延遲低；S3 backend 的設定先留著，要用時打開
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  # 遠端 backend（S3 + DynamoDB），正式環境建議打開
  # backend "s3" {
  #   bucket         = "asiayo-terraform-state"
  #   key            = "eks/terraform.tfstate"
  #   region         = "ap-northeast-1"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

# Kubernetes provider：用 EKS 的 endpoint + token 認證
# eks.tf 的 kubernetes_storage_class 資源需要這個 provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}
