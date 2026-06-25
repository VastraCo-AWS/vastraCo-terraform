resource "random_password" "jwt" {
  length  = 64
  special = false
}

################################################################################
# vastraco/db-creds
################################################################################
resource "aws_secretsmanager_secret" "db_creds" {
  name                    = "vastraco/db-creds"
  description             = "PostgreSQL credentials for VastraCo microservices"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 7

  tags = merge(var.tags, {
    Name = "vastraco-db-creds"
  })
}

resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = aws_secretsmanager_secret.db_creds.id

  secret_string = jsonencode({
    host     = var.db_endpoint
    port     = 5432
    dbname   = var.db_name
    username = var.db_username
    password = var.db_password
  })
}

################################################################################
# vastraco/jwt-secret
################################################################################
resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "vastraco/jwt-secret"
  description             = "JWT signing secret for VastraCo auth"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 7

  tags = merge(var.tags, {
    Name = "vastraco-jwt-secret"
  })
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id = aws_secretsmanager_secret.jwt_secret.id

  secret_string = jsonencode({
    jwt_secret = random_password.jwt.result
  })
}

################################################################################
# vastraco/app-secrets
################################################################################
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "vastraco/app-secrets"
  description             = "General application secrets for VastraCo"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 7

  tags = merge(var.tags, {
    Name = "vastraco-app-secrets"
  })
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id

  secret_string = jsonencode({
    environment  = var.environment
    service_name = var.project_name
    # Populate additional keys post-deployment as needed
  })
}
