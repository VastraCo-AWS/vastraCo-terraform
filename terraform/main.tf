# ACM for CloudFront and WAF must be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.common_tags
  }
}

################################################################################
# VPC
################################################################################
module "vpc" {
  source = "./modules/vpc"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  azs                      = local.azs
  aws_region               = var.aws_region
  tags                     = local.common_tags
}

################################################################################
# KMS
################################################################################
module "kms" {
  source = "./modules/kms"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  tags         = local.common_tags
}

################################################################################
# IAM
################################################################################
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

################################################################################
# EKS
################################################################################
module "eks" {
  source = "./modules/eks"

  project_name           = var.project_name
  environment            = var.environment
  kubernetes_version     = var.kubernetes_version
  cluster_role_arn       = module.iam.eks_cluster_role_arn
  node_role_arn          = module.iam.eks_node_role_arn
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  public_subnet_ids      = module.vpc.public_subnet_ids
  vpc_id                 = module.vpc.vpc_id
  vpc_cidr               = var.vpc_cidr
  node_instance_type     = var.node_instance_type
  node_desired_size      = var.node_desired_size
  node_min_size          = var.node_min_size
  node_max_size          = var.node_max_size
  kms_key_arn            = module.kms.key_arn
  tags                   = local.common_tags

  depends_on = [module.iam, module.vpc, module.kms]
}

################################################################################
# S3 - Product Images
################################################################################
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms.key_arn
  tags         = local.common_tags

  depends_on = [module.kms]
}

################################################################################
# IRSA
################################################################################
module "irsa" {
  source = "./modules/irsa"

  project_name                 = var.project_name
  environment                  = var.environment
  cluster_oidc_issuer_url      = module.eks.cluster_oidc_issuer_url
  s3_product_images_bucket_arn = module.s3.bucket_arn
  kms_key_arn                  = module.kms.key_arn
  tags                         = local.common_tags

  depends_on = [module.eks, module.s3, module.kms]
}

################################################################################
# RDS
################################################################################
module "rds" {
  source = "./modules/rds"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  private_db_subnet_ids      = module.vpc.private_db_subnet_ids
  eks_node_security_group_id = module.eks.node_security_group_id
  kms_key_arn                = module.kms.key_arn
  db_name                    = var.db_name
  db_username                = var.db_username
  db_instance_class          = var.db_instance_class
  db_engine_version          = var.db_engine_version
  tags                       = local.common_tags

  depends_on = [module.vpc, module.eks, module.kms]
}

################################################################################
# Secrets Manager
################################################################################
module "secretsmanager" {
  source = "./modules/secretsmanager"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms.key_arn
  db_password  = module.rds.db_password
  db_endpoint  = module.rds.db_endpoint
  db_name      = var.db_name
  db_username  = var.db_username
  tags         = local.common_tags

  depends_on = [module.rds, module.kms]
}

################################################################################
# WAF (CLOUDFRONT scope - must target aws.us_east_1 provider)
################################################################################
module "waf" {
  source = "./modules/waf"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags

  providers = {
    aws = aws.us_east_1
  }
}

################################################################################
# Route53 & ACM
# - only creates the certificate and validation records.
# - Route53 A-records for CloudFront are created below after cloudfront runs.
################################################################################
module "route53" {
  source = "./modules/route53"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
  aws_region   = var.aws_region
  tags         = local.common_tags

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

################################################################################
# ALB (needs validated ACM cert)
################################################################################
module "alb" {
  source = "./modules/alb"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  eks_node_security_group_id = module.eks.node_security_group_id
  certificate_arn            = module.route53.acm_certificate_arn
  tags                       = local.common_tags

  depends_on = [module.vpc, module.eks, module.route53]
}

################################################################################
# CloudFront
################################################################################
module "cloudfront" {
  source = "./modules/cloudfront"

  project_name                   = var.project_name
  environment                    = var.environment
  alb_dns_name                   = module.alb.alb_dns_name
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  s3_oac_id                      = module.s3.oac_id
  waf_web_acl_arn                = module.waf.web_acl_arn
  acm_certificate_arn            = module.route53.acm_certificate_arn
  domain_name                    = var.domain_name
  tags                           = local.common_tags

  depends_on = [module.alb, module.s3, module.waf, module.route53]
}

################################################################################
# Route53 - DNS A records pointing to CloudFront (post-distribution)
################################################################################
resource "aws_route53_record" "apex" {
  zone_id = module.route53.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "www" {
  zone_id = module.route53.hosted_zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

################################################################################
# ECR Repositories
################################################################################
locals {
  ecr_services = ["frontend-service", "user-service", "product-service", "order-service", "ai-service"]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(local.ecr_services)

  name                 = each.key
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, { Name = each.key })
}

resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

################################################################################
# Monitoring
################################################################################
module "monitoring" {
  source = "./modules/monitoring"

  project_name   = var.project_name
  environment    = var.environment
  cluster_name   = module.eks.cluster_name
  alb_arn_suffix = module.alb.alb_arn_suffix
  rds_identifier = module.rds.rds_identifier
  kms_key_arn    = module.kms.key_arn
  alert_email    = var.alert_email
  tags           = local.common_tags

  depends_on = [module.eks, module.alb, module.rds, module.kms]
}
