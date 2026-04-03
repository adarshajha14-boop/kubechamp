# EKS Module Variables

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes cluster version"
  type        = string
  default     = "1.27"
}

variable "vpc_id" {
  description = "VPC ID for the cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the cluster"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the cluster"
  type        = list(string)
  default     = []
}

variable "control_plane_cidr" {
  description = "CIDR block for control plane security group"
  type        = string
}

variable "node_groups" {
  description = "Node group configurations"
  type = map(object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
    disk_size      = number
    capacity_type  = string
    labels         = optional(map(string))
    taints         = optional(list(object({ key = string, value = string, effect = string })))
  }))
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Enable Metrics Server"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI Driver"
  type        = bool
  default     = true
}

variable "enable_efs_csi_driver" {
  description = "Enable EFS CSI Driver"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
