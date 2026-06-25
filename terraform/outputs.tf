################################################################################
# Network
################################################################################
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs"
  value       = module.vpc.private_db_subnet_ids
}

################################################################################
# EKS
################################################################################
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  description = "EKS cluster CA certificate (base64)"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "eks_node_security_group_id" {
  description = "Security group ID of EKS worker nodes"
  value       = module.eks.node_security_group_id
}

################################################################################
# IRSA Role ARNs (annotate K8s service accounts with these)
################################################################################
output "irsa_ai_service_role_arn" {
  description = "IRSA role ARN for ai-service Kubernetes service account"
  value       = module.irsa.ai_service_role_arn
}

output "irsa_product_service_role_arn" {
  description = "IRSA role ARN for product-service Kubernetes service account"
  value       = module.irsa.product_service_role_arn
}

output "irsa_user_service_role_arn" {
  description = "IRSA role ARN for user-service Kubernetes service account"
  value       = module.irsa.user_service_role_arn
}

output "irsa_order_service_role_arn" {
  description = "IRSA role ARN for order-service Kubernetes service account"
  value       = module.irsa.order_service_role_arn
}

################################################################################
# Database
################################################################################
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint hostname"
  value       = module.rds.db_endpoint
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = module.rds.db_port
}

output "rds_db_name" {
  description = "PostgreSQL database name"
  value       = module.rds.db_name
}

################################################################################
# Secrets
################################################################################
output "secret_arn_db_creds" {
  description = "ARN of the DB credentials secret in Secrets Manager"
  value       = module.secretsmanager.db_creds_secret_arn
}

output "secret_arn_jwt" {
  description = "ARN of the JWT secret in Secrets Manager"
  value       = module.secretsmanager.jwt_secret_arn
}

output "secret_arn_app" {
  description = "ARN of the app secrets in Secrets Manager"
  value       = module.secretsmanager.app_secrets_arn
}

################################################################################
# Edge / Traffic
################################################################################
output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

################################################################################
# S3
################################################################################
output "product_images_bucket" {
  description = "Product images S3 bucket name"
  value       = module.s3.bucket_id
}

################################################################################
# KMS
################################################################################
output "kms_key_arn" {
  description = "CMK ARN used for encryption"
  value       = module.kms.key_arn
}

################################################################################
# Monitoring
################################################################################
output "sns_alerts_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  value       = module.monitoring.sns_topic_arn
}

################################################################################
# ECR
################################################################################
output "ecr_repository_urls" {
  description = "ECR repository URLs for each service"
  value       = { for name, repo in aws_ecr_repository.services : name => repo.repository_url }
}

################################################################################
# kubectl config helper
################################################################################
output "kubeconfig_command" {
  description = "Run this command to update your kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
