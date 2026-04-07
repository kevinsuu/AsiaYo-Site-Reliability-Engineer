# VPC：跨 3 個 AZ，single_nat_gateway = false 避免 NAT GW 單點故障
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}c", "${var.aws_region}d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  # EKS 需要這些 tag 才能識別 subnet 給 Load Balancer 用
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"            = 1
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "asiayo"
  }
}
