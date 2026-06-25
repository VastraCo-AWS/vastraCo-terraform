#!/usr/bin/env bash
# =============================================================================
# VastraCo — GitHub Repository Variables & Secrets Setup
# =============================================================================
# Prerequisites:
#   - GitHub CLI (gh) installed and authenticated  (gh auth login)
#   - Run setup-aws-oidc.sh first to generate .aws-setup-outputs.env
#   - Repository must already exist on GitHub
#
# Usage:
#   chmod +x scripts/setup-github.sh
#   ./scripts/setup-github.sh
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

prompt_default() {
  # Usage: value=$(prompt_default "Label" "default")
  local label="$1" default="$2"
  read -rp "  ${label} [${default}]: " val
  echo "${val:-$default}"
}

prompt_secret() {
  # Usage: value=$(prompt_secret "Label")
  local label="$1"
  read -rsp "  ${label} (hidden): " val
  echo ""   # newline after hidden input
  echo "$val"
}

# ── Constants ──────────────────────────────────────────────────────────────────
GITHUB_ORG="VastraCo-AWS"
GITHUB_REPO="vastraCo-terraform"
REPO_FULL="${GITHUB_ORG}/${GITHUB_REPO}"
OUTPUTS_FILE="scripts/.aws-setup-outputs.env"

# ── 1. Verify prerequisites ────────────────────────────────────────────────────
header "Step 1 — Verifying prerequisites"

command -v gh &>/dev/null || error "GitHub CLI (gh) not found. Install from https://cli.github.com/"
info "gh version: $(gh --version | head -1)"

info "Checking gh authentication..."
gh auth status 2>/dev/null || error "Not authenticated. Run: gh auth login"
success "gh CLI authenticated."

# ── 2. Load AWS outputs ────────────────────────────────────────────────────────
header "Step 2 — Loading AWS setup outputs"

ROLE_ARN=""
if [ -f "$OUTPUTS_FILE" ]; then
  # shellcheck source=/dev/null
  source "$OUTPUTS_FILE"
  ROLE_ARN="${ROLE_ARN:-}"
  success "Loaded ${OUTPUTS_FILE}"
  info "  IAM Role ARN: ${ROLE_ARN}"
else
  warn "${OUTPUTS_FILE} not found."
  warn "Either run setup-aws-oidc.sh first, or enter the role ARN manually below."
fi

# ── 3. Collect variable & secret values ───────────────────────────────────────
header "Step 3 — Collecting configuration values"
echo "  Press Enter to accept the [default] shown in brackets."
echo ""

# Variables (not sensitive)
AWS_REGION_VAL=$(prompt_default  "AWS_REGION (GitHub Variable)"    "us-east-1")
DOMAIN_NAME_VAL=$(prompt_default "DOMAIN_NAME (GitHub Variable)"   "vastraco.online")

echo ""

# Secrets (sensitive)
if [ -z "$ROLE_ARN" ]; then
  ROLE_ARN=$(prompt_default "AWS_ROLE_TO_ASSUME (GitHub Secret)" \
    "arn:aws:iam::ACCOUNT_ID:role/vastraco-github-actions-role")
fi

ALERT_EMAIL_VAL=$(prompt_default "ALERT_EMAIL (GitHub Secret — TF_VAR_alert_email)" \
  "ops@vastraco.online")

echo ""
echo "  Email notification credentials"
EMAIL_USER_VAL=$(prompt_default "EMAIL_USERNAME (Gmail sender address)" "")
EMAIL_PASS_VAL=$(prompt_secret  "EMAIL_PASSWORD (Gmail App Password — 16-char)")
EMAIL_TO_VAL=$(prompt_default   "EMAIL_TO (recipient address)"          "")

# ── 4. Set GitHub Actions Variables ───────────────────────────────────────────
header "Step 4 — Setting GitHub Actions Variables"

set_variable() {
  local name="$1" value="$2"
  info "Setting variable: ${name}"
  gh variable set "$name" \
    --repo  "$REPO_FULL" \
    --body  "$value"
  success "${name} = ${value}"
}

set_variable "AWS_REGION"   "$AWS_REGION_VAL"
set_variable "DOMAIN_NAME"  "$DOMAIN_NAME_VAL"

# ── 5. Set GitHub Actions Secrets ─────────────────────────────────────────────
header "Step 5 — Setting GitHub Actions Secrets"

set_secret() {
  local name="$1" value="$2"
  if [ -z "$value" ]; then
    warn "Skipping ${name} — no value provided."
    return
  fi
  info "Setting secret: ${name}"
  gh secret set "$name" \
    --repo  "$REPO_FULL" \
    --body  "$value"
  success "${name} set (value hidden)."
}

set_secret "AWS_ROLE_TO_ASSUME" "$ROLE_ARN"
set_secret "ALERT_EMAIL"        "$ALERT_EMAIL_VAL"
set_secret "EMAIL_USERNAME"     "$EMAIL_USER_VAL"
set_secret "EMAIL_PASSWORD"     "$EMAIL_PASS_VAL"
set_secret "EMAIL_TO"           "$EMAIL_TO_VAL"

# ── 6. Verify what was set ─────────────────────────────────────────────────────
header "Step 6 — Verification"

info "Current repository variables:"
gh variable list --repo "$REPO_FULL" 2>/dev/null || warn "Could not list variables."

echo ""
info "Current repository secrets (names only — values are always hidden):"
gh secret list --repo "$REPO_FULL" 2>/dev/null || warn "Could not list secrets."

# ── 7. Summary ────────────────────────────────────────────────────────────────
header "GitHub Configuration Complete"
echo -e "${GREEN}"
echo "  Repository : https://github.com/${REPO_FULL}"
echo ""
echo "  Variables set:"
echo "    AWS_REGION   = ${AWS_REGION_VAL}"
echo "    DOMAIN_NAME  = ${DOMAIN_NAME_VAL}"
echo ""
echo "  Secrets set:"
echo "    AWS_ROLE_TO_ASSUME  (OIDC role ARN)"
echo "    ALERT_EMAIL         (Terraform alert_email var)"
echo "    EMAIL_USERNAME      (Gmail sender)"
echo "    EMAIL_PASSWORD      (Gmail App Password)"
echo "    EMAIL_TO            (notification recipient)"
echo ""
echo "  Remaining manual step:"
echo "    Create the 'production-infra' GitHub Environment with required"
echo "    reviewers via: Repository → Settings → Environments"
echo ""
echo "  Workflow file:"
echo "    .github/workflows/terraform-apply.yml"
echo -e "${RESET}"
