#!/usr/bin/env bash
# =============================================================================
# VastraCo — AWS OIDC Provider & GitHub Actions IAM Role Setup
# =============================================================================
# Prerequisites:
#   - AWS CLI v2 installed and configured (aws configure / SSO / env vars)
#   - Sufficient IAM permissions to create OIDC providers and IAM roles
#
# Usage:
#   chmod +x scripts/setup-aws-oidc.sh
#   ./scripts/setup-aws-oidc.sh
# =============================================================================

set -euo pipefail

# ── Colour helpers ─────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}$*${RESET}"; echo "$(printf '─%.0s' {1..60})"; }

# ── Constants ──────────────────────────────────────────────────────────────────
GITHUB_ORG="VastraCo-AWS"
GITHUB_REPO="vastraCo-terraform"
ROLE_NAME="vastraco-github-actions-role"
OIDC_URL="https://token.actions.githubusercontent.com"
OIDC_THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"
OIDC_AUDIENCE="sts.amazonaws.com"

# ── 1. Verify prerequisites ────────────────────────────────────────────────────
header "Step 1 — Verifying prerequisites"

command -v aws &>/dev/null || error "AWS CLI is not installed. Install it from https://aws.amazon.com/cli/"
info "AWS CLI found: $(aws --version 2>&1 | head -1)"

info "Checking AWS credentials..."
CALLER_IDENTITY=$(aws sts get-caller-identity --output json 2>/dev/null) \
  || error "AWS credentials not configured. Run 'aws configure' or set AWS_PROFILE."

ACCOUNT_ID=$(echo "$CALLER_IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
CALLER_ARN=$(echo "$CALLER_IDENTITY" | grep -o '"Arn": "[^"]*"'     | cut -d'"' -f4)

success "Authenticated as: ${CALLER_ARN}"
success "AWS Account ID : ${ACCOUNT_ID}"

OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

# ── 2. Create OIDC Provider ────────────────────────────────────────────────────
header "Step 2 — Creating GitHub Actions OIDC Provider"

if aws iam get-open-id-connect-provider \
     --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" \
     &>/dev/null; then
  warn "OIDC provider already exists: ${OIDC_PROVIDER_ARN}"
  warn "Skipping creation."
else
  info "Creating OIDC provider..."
  aws iam create-open-id-connect-provider \
    --url          "$OIDC_URL"            \
    --client-id-list "$OIDC_AUDIENCE"    \
    --thumbprint-list "$OIDC_THUMBPRINT" \
    --tags "Key=Project,Value=vastraco" "Key=ManagedBy,Value=setup-script" \
    --output json > /dev/null

  success "OIDC provider created: ${OIDC_PROVIDER_ARN}"
fi

# ── 3. Write trust policy JSON ─────────────────────────────────────────────────
header "Step 3 — Writing IAM Trust Policy"

TRUST_POLICY_FILE="/tmp/vastraco-trust-policy.json"

cat > "$TRUST_POLICY_FILE" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsOIDC",
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_PROVIDER_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "${OIDC_AUDIENCE}"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

success "Trust policy written to ${TRUST_POLICY_FILE}"
info "Scope: repo:${GITHUB_ORG}/${GITHUB_REPO}:*"

# ── 4. Create IAM Role ─────────────────────────────────────────────────────────
header "Step 4 — Creating IAM Role: ${ROLE_NAME}"

if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
  warn "IAM role '${ROLE_NAME}' already exists."
  warn "Updating trust policy on existing role..."
  aws iam update-assume-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-document "file://${TRUST_POLICY_FILE}" \
    > /dev/null
  success "Trust policy updated."
else
  info "Creating IAM role..."
  aws iam create-role \
    --role-name                  "$ROLE_NAME"             \
    --assume-role-policy-document "file://${TRUST_POLICY_FILE}" \
    --description "GitHub Actions OIDC role for VastraCo Terraform CI/CD" \
    --tags \
      "Key=Project,Value=vastraco" \
      "Key=ManagedBy,Value=GitHubActions" \
      "Key=Environment,Value=production" \
    --output json > /dev/null

  success "IAM role created: ${ROLE_ARN}"
fi

# ── 5. Attach Permissions Policy ───────────────────────────────────────────────
header "Step 5 — Attaching Permissions Policy"

# Check if already attached
ATTACHED=$(aws iam list-attached-role-policies \
  --role-name "$ROLE_NAME" \
  --query "AttachedPolicies[?PolicyName=='AdministratorAccess'].PolicyName" \
  --output text 2>/dev/null || echo "")

if [ "$ATTACHED" = "AdministratorAccess" ]; then
  warn "AdministratorAccess already attached to ${ROLE_NAME}."
else
  info "Attaching AdministratorAccess..."
  aws iam attach-role-policy \
    --role-name  "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

  success "AdministratorAccess attached."
fi

warn "IMPORTANT: AdministratorAccess is broad. For production, replace with a"
warn "           scoped policy that covers only the AWS services Terraform manages:"
warn "           EC2, EKS, RDS, S3, IAM, KMS, CloudFront, Route53, WAF, CloudWatch."

# ── 6. Write role ARN to a local env file ──────────────────────────────────────
header "Step 6 — Saving outputs"

ENV_OUT_FILE="scripts/.aws-setup-outputs.env"
cat > "$ENV_OUT_FILE" <<EOF
# Generated by setup-aws-oidc.sh — $(date -u +"%Y-%m-%dT%H:%M:%SZ")
AWS_ACCOUNT_ID=${ACCOUNT_ID}
OIDC_PROVIDER_ARN=${OIDC_PROVIDER_ARN}
ROLE_ARN=${ROLE_ARN}
EOF

success "Outputs saved to ${ENV_OUT_FILE}"
info "  Source this file or copy values to GitHub Secrets."

# ── Summary ────────────────────────────────────────────────────────────────────
header "Setup Complete"
echo -e "${GREEN}"
echo "  AWS Account ID   : ${ACCOUNT_ID}"
echo "  OIDC Provider ARN: ${OIDC_PROVIDER_ARN}"
echo "  IAM Role ARN     : ${ROLE_ARN}"
echo ""
echo "  Next step: run   ./scripts/setup-github.sh"
echo "  It will read ${ENV_OUT_FILE} and configure GitHub automatically."
echo -e "${RESET}"
