# =============================================================================
# Ledger Platform Infrastructure
# =============================================================================
# Terraform configuration for deploying Ledger services to AWS EKS.
# Demonstrates IaC security scanning with Snyk.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Backend configuration (commented for demo)
  # backend "s3" {
  #   bucket         = "ledger-terraform-state"
  #   key            = "infrastructure/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "ledger-terraform-locks"
  # }
}

# -----------------------------------------------------------------------------
# Provider Configuration
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ledger-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
      Team        = "platform"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "ledger-platform"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = var.environment == "dev"
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # Tags for EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Security: Enable encryption
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # Security: Enable logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Security: Private endpoint
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = var.environment == "dev"

  # Node groups
  eks_managed_node_groups = {
    platform = {
      name           = "platform-nodes"
      instance_types = var.node_instance_types

      min_size     = var.environment == "prod" ? 3 : 1
      max_size     = var.environment == "prod" ? 10 : 3
      desired_size = var.environment == "prod" ? 3 : 2

      # Security: Use latest AMI
      ami_type = "AL2_x86_64"

      # Security: Encrypt EBS
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      labels = {
        role = "platform"
      }

      tags = {
        NodeGroup = "platform"
      }
    }
  }

  tags = {
    Cluster = var.cluster_name
  }
}

# -----------------------------------------------------------------------------
# KMS Key for EKS Encryption
# -----------------------------------------------------------------------------

resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.cluster_name}-eks-key"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# -----------------------------------------------------------------------------
# ECR Repository for Container Images
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "services" {
  for_each = toset(["payments-api", "audit-service", "notification-service"])

  name                 = "ledger/${each.key}"
  image_tag_mutability = "IMMUTABLE"

  # Security: Enable image scanning
  image_scanning_configuration {
    scan_on_push = true
  }

  # Security: Encrypt images
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  tags = {
    Service = each.key
  }
}

resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.cluster_name}-ecr-key"
  }
}

# Lifecycle policy to clean old images
resource "aws_ecr_lifecycle_policy" "cleanup" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}
