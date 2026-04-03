# Variables for KubeChamp Platform

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be one of: dev, sit, prod"
  }
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "node_groups" {
  description = "EKS node group configurations"
  type = map(object({
    desired_size       = number
    min_size           = number
    max_size           = number
    instance_types     = list(string)
    disk_size          = number
    capacity_type      = string
    labels             = optional(map(string))
    taints             = optional(list(object({ key = string, value = string, effect = string })))
  }))

  default = {
    system = {
      desired_size  = 3
      min_size      = 2
      max_size      = 5
      instance_types = ["t3.medium"]
      disk_size      = 50
      capacity_type  = "ON_DEMAND"
      labels = {
        "workload-type" = "system"
        "node-pool"     = "system"
      }
    }
    applications = {
      desired_size  = 3
      min_size      = 2
      max_size      = 10
      instance_types = ["t3.large"]
      disk_size      = 100
      capacity_type  = "SPOT"
      labels = {
        "workload-type" = "applications"
        "node-pool"     = "applications"
      }
    }
  }
}

variable "enable_vault" {
  description = "Enable HashiCorp Vault"
  type        = bool
  default     = true
}

variable "enable_rds" {
  description = "Enable RDS database"
  type        = bool
  default     = false
}

variable "rds_engine" {
  description = "RDS engine (postgres, mysql, mariadb)"
  type        = string
  default     = "postgres"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Platform = "KubeChamp"
  }
}
