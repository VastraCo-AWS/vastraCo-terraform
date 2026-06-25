# Context & Instructions for Creating a GitHub Actions Workflow for VastraCo Terraform

## 1. Project Overview & Requirements
We are building a production-ready cloud-native microservices infrastructure on AWS for **VastraCo** using **Terraform** as Infrastructure as Code. The deployment needs to follow strict DevOps and GitOps practices, including a multi-stage GitHub Actions CI/CD pipeline for provisioning and managing resources.

Your task is to generate a GitHub Actions workflow file: `.github/workflows/terraform-apply.yml` (and provide configuration guidance) that adheres to the following specification.

### Key Capstone Requirements
- **Directory Isolation**: The Terraform files are located in the `terraform/` directory of the repository (not at the root).
- **Trigger**: The workflow should trigger on pushes or pull requests with changes to files inside the `terraform/` folder (e.g., `terraform/**`).
- **Pipeline Stages**:
  1. **Validation & Linting**: Check code formatting (`terraform fmt -check`) and run validation (`terraform validate`).
  2. **Plan**: Generate an execution plan (`terraform plan`) and output it (or post it as a PR comment) for review.
  3. **Manual Approval Gate**: Require a manual approval step before running the apply.
  4. **Apply**: Apply the changes on approval (`terraform apply -auto-approve`).
- **Security**: No static credentials should be exposed in logs. Secrets and cloud credentials must be managed securely. AWS access should preferably use **OIDC (OpenID Connect)** authentication (IAM Role to Assume) rather than long-lived Access Keys.

---

## 2. Repository Directory Structure
The repository contains two main folders related to Terraform:
- **`bootstrap/`**: Used once locally to provision the remote state resources.
  - S3 bucket: `vastraco-terraform-state-<random_suffix>` (encrypted using a custom KMS key, public access blocked, and versioning enabled).
  - DynamoDB table: `vastraco-terraform-locks` (billing mode: pay-per-request, partition key: `LockID`).
- **`terraform/`**: The core infrastructure directory containing the root module and submodules.
  - **`modules/`**:
    - `vpc`: Configures public and private subnets across multiple AZs.
    - `kms`: Provisions KMS customer managed keys (CMK) for encryption.
    - `iam`: Defines cluster/node roles and service accounts.
    - `eks`: Manages the EKS cluster (v1.29) and node groups.
    - `s3`: Manages the product images bucket.
    - `irsa`: Configures IAM Roles for Service Accounts (OIDC provider + pod-to-service IAM bindings).
    - `rds`: Provisions a PostgreSQL database in private DB subnets.
    - `secretsmanager`: Configures database credentials and connection parameters.
    - `waf`: Configures Web Application Firewall (scoped for CloudFront).
    - `route53`: Manages dns zones, validation records, and ACM certificates.
    - `alb`: Configures Application Load Balancer.
    - `cloudfront`: Sets up CDN caching with HTTPS and WAF integration.
    - `monitoring`: Configures CloudWatch log groups, RDS/ALB alarms, and SNS notifications.

---

## 3. Remote State Backend Config
The backend is configured in `terraform/providers.tf` and requires bootstrapping first. The configuration block is structured as:
```hcl
terraform {
  backend "s3" {
    bucket         = "vastraco-terraform-state-<suffix>"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "vastraco-terraform-locks"
    encrypt        = true
  }
}
```
*Note: The actual bucket name suffix is resolved dynamically from the bootstrap output.*

---

## 4. Multi-Provider & Regions Config
The codebase uses a multi-provider setup because certain resources (like WAF for CloudFront and ACM certificate validation) must be created in the `us-east-1` region, whereas other core infrastructure might be in the same or a different region:
- **Default AWS Provider**: Configured using `var.aws_region` (defaults to `us-east-1`).
- **US-East-1 Provider (Alias)**: Configured as `aws.us_east_1` (specifically for WAF, Route53, and ACM certificates).

This means the GitHub Actions runner must have permissions to manage resources globally/across these regions.

---

## 5. Instructions for Generating the GitHub Actions Workflow
Please write a production-grade, secure, and clean GitHub Actions YAML file (`.github/workflows/terraform-apply.yml`). The file must include:

### A. Workflow Triggers & General Setup
- Triggers on:
  - `pull_request` pointing to `main` or `develop` branches, restricted to paths `terraform/**`.
  - `push` to `main` or `develop` branches, restricted to paths `terraform/**`.
  - Also support `workflow_dispatch` for manual execution.
- Work directory: Run all Terraform steps with `working-directory: ./terraform`.
- Permissions: Must include `permissions: id-token: write, contents: read` to support AWS OIDC token exchange.

### B. Secrets & AWS OIDC Authentication
Use standard GitHub action `aws-actions/configure-aws-credentials` to authenticate.
- Support authenticating via **OIDC Role Assume** (recommended):
  - Read `AWS_ROLE_TO_ASSUME` from GitHub secrets/vars.
  - Read `AWS_REGION` (default to `us-east-1`).
- Provide an fallback option block in comments for standard `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` credentials in case the user does not have OIDC configured.

### C. Job Structure
1. **`terraform-plan` Job**:
   - Runs on `ubuntu-latest`.
   - Checks out repository.
   - Installs Terraform (via `hashicorp/setup-terraform`).
   - Runs `terraform fmt -check`.
   - Runs `terraform init`.
   - Runs `terraform validate`.
   - Runs `terraform plan -no-color -out=tfplan`.
   - Uploads the plan artifact (`tfplan`) so it can be applied in the next job.
   - *Optional but highly recommended*: Posts the plan output to the PR comments if triggered by a pull request, so the reviewer doesn't have to look at the runner logs.
2. **`terraform-apply` Job**:
   - Runs on `ubuntu-latest`.
   - **Depends on `terraform-plan`**.
   - Triggers **only on pushes/merges to target branches** (e.g., `main` or `develop`), not on PRs.
   - Configures a **GitHub Environment** (e.g., `production-infra`) to enforce **manual approval** gates.
   - Checks out repository.
   - Authenticates to AWS.
   - Installs Terraform.
   - Downloads the plan artifact (`tfplan`).
   - Runs `terraform init`.
   - Runs `terraform apply -auto-approve tfplan`.

---

## 6. Additional Guidance Needed
Please provide clear step-by-step instructions on:
1. **GitHub Repository Settings**: How to set up the GitHub environment (`production-infra`) and configure the required reviewers/approvals.
2. **Required GitHub Secrets**: A checklist of the specific secrets that must be added to the repository settings (e.g., `AWS_ROLE_TO_ASSUME` or Access Keys, `ALERT_EMAIL`, etc.).
3. **AWS OIDC Configuration**: The CloudFormation template or AWS console instructions needed to establish GitHub Actions as an OIDC identity provider in the AWS account.
4. **Terraform Variables**: How to handle variables in CI (e.g., injecting variables via environment variables starting with `TF_VAR_` or uploading a secure `terraform.tfvars` file).
