# Main Terraform configuration for KubeChamp Platform environments

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }

  # Uncomment to use remote state in S3
  # backend "s3" {
  #   bucket         = "kubechamp-terraform-state"
  #   key            = "platform/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Platform    = "KubeChamp"
      ManagedBy   = "Terraform"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_ca_cert)
  token                  = data.aws_eks_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_ca_cert)
    token                  = data.aws_eks_auth.cluster.token
  }
}

# Get auth token for Kubernetes provider
data "aws_eks_auth" "cluster" {
  name = module.eks_cluster.cluster_name
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  environment       = var.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnets   = var.private_subnets
  public_subnets    = var.public_subnets

  tags = {
    Name = "kubechamp-${var.environment}-vpc"
  }
}

# EKS Cluster Module
module "eks_cluster" {
  source = "./modules/eks"

  environment         = var.environment
  cluster_name        = "kubechamp-${var.environment}"
  cluster_version     = var.kubernetes_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  control_plane_cidr  = var.vpc_cidr

  node_groups = var.node_groups

  enable_cluster_autoscaler = true
  enable_metrics_server     = true
  enable_ebs_csi_driver     = true
  enable_efs_csi_driver     = true

  tags = {
    Name = "kubechamp-${var.environment}-eks"
  }
}

# Security Group for security policy enforcement
resource "aws_security_group" "pod_security" {
  name        = "kubechamp-${var.environment}-pod-security"
  description = "Security group for pod network policies"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow intra-cluster communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "kubechamp-${var.environment}-pod-security"
  }
}

# Secrets Manager for Vault integration
resource "aws_secretsmanager_secret" "vault_unseal_key" {
  count                   = var.enable_vault ? 1 : 0
  name                    = "kubechamp/${var.environment}/vault-unseal-key"
  recovery_window_in_days = 7
  description             = "Vault unseal key for ${var.environment}"

  tags = {
    Name = "kubechamp-vault-key-${var.environment}"
  }
}

# RDS for persistent services (if needed)
module "rds" {
  count  = var.enable_rds ? 1 : 0
  source = "./modules/rds"

  environment             = var.environment
  engine                  = var.rds_engine
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  multi_az                = var.environment == "prod" ? true : false
  backup_retention_period = var.environment == "prod" ? 30 : 7

  db_subnet_group_name   = module.vpc.db_subnet_group_name
  vpc_security_group_ids = [module.vpc.vpc_id]

  tags = {
    Name = "kubechamp-${var.environment}-rds"
  }
}

# ECR for container image registry
resource "aws_ecr_repository" "kubechamp" {
  name                 = "kubechamp/${var.environment}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = {
    Name = "kubechamp-${var.environment}-ecr"
  }
}

# CloudWatch Log Group for cluster logs
resource "aws_cloudwatch_log_group" "cluster_logs" {
  name              = "/aws/eks/kubechamp-${var.environment}"
  retention_in_days = var.environment == "prod" ? 90 : 30

  tags = {
    Name = "kubechamp-${var.environment}-logs"
  }
}

# Outputs
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks_cluster.cluster_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.kubechamp.repository_url
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
