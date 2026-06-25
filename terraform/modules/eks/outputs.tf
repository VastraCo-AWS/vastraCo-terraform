output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority for the EKS cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "node_security_group_id" {
  description = "Security group ID attached to EKS worker nodes (EKS-managed cluster SG)"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_security_group_id" {
  description = "Security group ID for the EKS control plane"
  value       = aws_security_group.cluster.id
}
