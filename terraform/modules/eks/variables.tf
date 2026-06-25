variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for EKS node group"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private subnet IDs for EKS node group"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the cluster endpoint"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block (used in security group rules)"
  type        = string
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
}

variable "node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of EKS worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of EKS worker nodes"
  type        = number
}

variable "kms_key_arn" {
  description = "KMS key ARN for envelope encryption of Kubernetes secrets"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
