variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (dynamic origin)"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 product images bucket (static origin)"
  type        = string
}

variable "s3_oac_id" {
  description = "CloudFront Origin Access Control ID for S3"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL to attach"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1 for CloudFront)"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (e.g. vastraco.online)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
