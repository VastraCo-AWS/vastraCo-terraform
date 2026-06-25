variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt secrets"
  type        = string
}

variable "db_password" {
  description = "Database master password (from random_password)"
  type        = string
  sensitive   = true
}

variable "db_endpoint" {
  description = "RDS endpoint hostname"
  type        = string
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
