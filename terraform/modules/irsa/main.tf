data "aws_caller_identity" "current" {}

data "tls_certificate" "eks_oidc" {
  url = var.cluster_oidc_issuer_url
}

################################################################################
# OIDC Provider for EKS
################################################################################
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = var.cluster_oidc_issuer_url

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-oidc-provider"
  })
}

locals {
  oidc_provider_arn = aws_iam_openid_connect_provider.eks.arn
  oidc_host         = replace(var.cluster_oidc_issuer_url, "https://", "")
}

################################################################################
# Helper: reusable trust policy factory
################################################################################
data "aws_iam_policy_document" "trust" {
  for_each = {
    ai-service      = "ai-service-sa"
    product-service = "product-service-sa"
    user-service    = "user-service-sa"
    order-service   = "order-service-sa"
  }

  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:production:${each.value}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

################################################################################
# IRSA - AI Service (Secrets Manager only — Bedrock removed, migrated to Groq)
################################################################################
resource "aws_iam_role" "ai_service" {
  name               = "${var.project_name}-${var.environment}-irsa-ai-service"
  assume_role_policy = data.aws_iam_policy_document.trust["ai-service"].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "ai_service_secrets" {
  name = "secrets-manager-read"
  role = aws_iam_role.ai_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:vastraco/*"
      },
      {
        Sid      = "KMSDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.kms_key_arn
      },
    ]
  })
}

################################################################################
# IRSA - Product Service (S3 + Secrets Manager)
################################################################################
resource "aws_iam_role" "product_service" {
  name               = "${var.project_name}-${var.environment}-irsa-product-service"
  assume_role_policy = data.aws_iam_policy_document.trust["product-service"].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "product_service_s3" {
  name = "s3-product-images"
  role = aws_iam_role.product_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ProductImages"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          var.s3_product_images_bucket_arn,
          "${var.s3_product_images_bucket_arn}/*",
        ]
      },
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:vastraco/*"
      },
      {
        Sid      = "KMSDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = var.kms_key_arn
      },
    ]
  })
}

################################################################################
# IRSA - User Service (Secrets Manager)
################################################################################
resource "aws_iam_role" "user_service" {
  name               = "${var.project_name}-${var.environment}-irsa-user-service"
  assume_role_policy = data.aws_iam_policy_document.trust["user-service"].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "user_service_secrets" {
  name = "secrets-manager-read"
  role = aws_iam_role.user_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:vastraco/*"
      },
      {
        Sid      = "KMSDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.kms_key_arn
      },
    ]
  })
}

################################################################################
# IRSA - Order Service (Secrets Manager)
################################################################################
resource "aws_iam_role" "order_service" {
  name               = "${var.project_name}-${var.environment}-irsa-order-service"
  assume_role_policy = data.aws_iam_policy_document.trust["order-service"].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "order_service_secrets" {
  name = "secrets-manager-read"
  role = aws_iam_role.order_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:vastraco/*"
      },
      {
        Sid      = "KMSDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.kms_key_arn
      },
    ]
  })
}
