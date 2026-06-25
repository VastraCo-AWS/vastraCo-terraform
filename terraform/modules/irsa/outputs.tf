output "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "ai_service_role_arn" {
  description = "IRSA role ARN for ai-service"
  value       = aws_iam_role.ai_service.arn
}

output "product_service_role_arn" {
  description = "IRSA role ARN for product-service"
  value       = aws_iam_role.product_service.arn
}

output "user_service_role_arn" {
  description = "IRSA role ARN for user-service"
  value       = aws_iam_role.user_service.arn
}

output "order_service_role_arn" {
  description = "IRSA role ARN for order-service"
  value       = aws_iam_role.order_service.arn
}
