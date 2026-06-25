variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL from the EKS cluster"
  type        = string
}

variable "s3_product_images_bucket_arn" {
  description = "ARN of the S3 product images bucket"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key (for Secrets Manager decryption)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
