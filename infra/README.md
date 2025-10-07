# JOTIQ Infrastructure-as-Code

This repository provisions the AWS infrastructure for the multi-tenant SaaS platform **JOTIQ** using Terraform and GitHub Actions. It follows a modular structure and supports the `dev`, `staging`, and `prod` environments.

## Prerequisites

1. **Tools**
   - Terraform >= 1.5
   - AWS CLI >= 2.13 with credentials that can provision the remote state resources
   - Make
2. **Remote State Resources** (create once per AWS account/region)
   ```bash
   aws s3api create-bucket \
     --bucket <jotiq-terraform-state> \
     --create-bucket-configuration LocationConstraint=<region>

   aws s3api put-bucket-versioning \
     --bucket <jotiq-terraform-state> \
     --versioning-configuration Status=Enabled

   aws dynamodb create-table \
     --table-name <jotiq-terraform-locks> \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

3. **Certificates & DNS**
   - Issue ACM certificates in the relevant regions:
     - `us-east-1` for CloudFront (`assets.jotiq.com`).
     - The environment region for ALB (`api.jotiq.com`, `app.jotiq.com`).
   - Ensure Route53 hosted zones exist or provide existing hosted zone IDs.

4. **GitHub OIDC IAM Role**
   - Using the Terraform modules in this repo (`modules/iam_roles`), create a deploy role in the target account.
   - Add the role ARN to the repository secret `AWS_OIDC_ROLE_ARN`.

## Repository Layout

```
infra/
  terraform/
    global/        # Remote state bootstrap + org-wide security
    modules/       # Reusable building blocks
    envs/          # Environment compositions (dev, staging, prod)
.github/workflows  # CI/CD pipelines
```

## Getting Started

1. **Bootstrap Backend**
   ```bash
   cd infra/terraform/global/backend
   terraform init -backend-config="bucket=<jotiq-terraform-state>" \
                   -backend-config="key=global/backend/terraform.tfstate" \
                   -backend-config="dynamodb_table=<jotiq-terraform-locks>" \
                   -backend-config="region=<region>"
   terraform workspace new default || true
   terraform plan -out tfplan
   terraform apply tfplan
   ```

   The backend configuration uses variables (`state_bucket`, `state_key_prefix`, `lock_table`, `region`) that can be passed via `-var` flags or `terraform.tfvars`.

2. **Configure Environments**
   For each environment (`dev`, `staging`, `prod`):
   ```bash
   cd infra/terraform/envs/<env>
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with environment-specific values.
   terraform init -backend-config="bucket=<jotiq-terraform-state>" \
                   -backend-config="key=<env>/terraform.tfstate" \
                   -backend-config="dynamodb_table=<jotiq-terraform-locks>" \
                   -backend-config="region=<region>"
   terraform workspace new <env> || true
   ```

3. **Terraform Commands**
   Use the provided Makefile wrappers from the repository root:
   ```bash
   make fmt
   make validate ENV=<env>
   make plan ENV=<env>
   make apply ENV=<env>
   ```
   - `ENV` defaults to `dev` when not specified.
   - `make bootstrap` runs the backend bootstrap in `infra/terraform/global/backend`.

4. **GitHub Actions Pipelines**
   - `terraform-plan-apply.yml` runs `fmt`, `validate`, and `plan` on pull requests and applies on pushes to `main` after manual approval.
   - `build-deploy-ecs.yml` builds Docker images for the `api`, `web`, and `worker` services, pushes to ECR, and triggers CodeDeploy blue/green (for `api` and `web`) or rolling (for `worker`).

## Outputs

Key outputs produced per environment include:

- ALB DNS name and Security Group IDs
- ECS cluster and service names for `api`, `web`, and `worker`
- CloudFront distribution domain for assets
- SQS queue ARNs (primary and DLQ)
- CloudWatch dashboard and alarm ARNs
- SES domain identity ARNs and DKIM records

These outputs appear after `terraform apply` and are consumed by CI/CD for deployments.

## Notes

- Secrets (e.g., `MONGODB_URI`, `JWT_SECRET`) are stored in AWS Secrets Manager and referenced by ECS task definitions via environment variables and secrets configuration.
- MongoDB Atlas is managed separately. Terraform stores only the connection strings and credentials in Secrets Manager.
- All S3 buckets enforce encryption at rest, block public access, and use lifecycle policies for cost optimization.
- VPC endpoints minimize the need for NAT gateways when interacting with AWS services from private subnets.

