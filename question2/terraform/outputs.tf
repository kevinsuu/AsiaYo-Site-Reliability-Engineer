output "cluster_endpoint" {
  description = "EKS Cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS Cluster 名稱"
  value       = module.eks.cluster_name
}

output "cluster_certificate_authority_data" {
  description = "EKS Cluster CA 憑證（base64）"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
