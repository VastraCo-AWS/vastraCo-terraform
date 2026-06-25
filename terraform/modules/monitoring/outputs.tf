output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "eks_log_group_name" {
  description = "CloudWatch log group name for EKS cluster logs"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "application_log_group_name" {
  description = "CloudWatch log group name for application logs"
  value       = aws_cloudwatch_log_group.application.name
}

output "rds_log_group_name" {
  description = "CloudWatch log group name for RDS logs"
  value       = aws_cloudwatch_log_group.rds.name
}
