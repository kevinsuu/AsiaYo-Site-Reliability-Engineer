# EKS：Control Plane 由 AWS 管，Node Group 跨 AZ，IRSA 做最小權限
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Node 在 private subnet，不直接對外暴露
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa = true  # OIDC Provider，IRSA 必須

  # addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    general = {
      desired_size = 3
      min_size     = 2
      max_size     = 6

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      subnet_ids = module.vpc.private_subnets

      labels = {
        role = "general"
      }

      tags = {
        Environment = var.environment
      }
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "asiayo"
  }
}

# EBS CSI Driver IRSA，PVC 動態佈建需要這個
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${var.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# S3：存放使用者上傳的檔案，stateless 設計的核心
resource "aws_s3_bucket" "app_uploads" {
  bucket = "${var.cluster_name}-app-uploads"

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = "asiayo"
  }
}

# 封鎖公開存取，全部走 IAM
resource "aws_s3_bucket_public_access_block" "app_uploads" {
  bucket                  = aws_s3_bucket.app_uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IRSA：Pod 透過 ServiceAccount 取得 S3 權限，不用把 Access Key 塞進環境變數
module "app_s3_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-app-s3"

  role_policy_arns = {
    s3 = aws_iam_policy.app_s3.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["asiayo:asiayo-app-sa"]
    }
  }
}

# 只開放這個 bucket，最小權限
resource "aws_iam_policy" "app_s3" {
  name = "${var.cluster_name}-app-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.app_uploads.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.app_uploads.arn
      }
    ]
  })
}

# gp3 比 gp2 便宜又快，設為 default StorageClass
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}
