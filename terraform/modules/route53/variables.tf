variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (e.g. vastraco.online)"
  type        = string
}

variable "aws_region" {
  description = "AWS region (ACM certificate must be in us-east-1 for CloudFront)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
