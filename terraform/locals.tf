locals {
  common_tags = {
    Project     = var.project_name
    Environment = "production"
    Owner       = "Freshers-Team"
    ManagedBy   = "Terraform"
  }

  # Availability zones
  azs = ["${var.aws_region}a", "${var.aws_region}b"]
}
