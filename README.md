# AWS Backend Architecture - Phase 1 (Terraform)

This repository contains the Terraform configuration for Phase 1 of the AWS Backend Architecture Lab. It sets up a highly available, multi-tier environment on AWS, following best practices for security and scalability.

## Overview

The infrastructure provisioned includes:
- **Networking**: A VPC with public, private, and database subnets across all available Availability Zones, including NAT Gateway for outbound traffic from private subnets.
- **Compute**: An Auto Scaling Group (ASG) behind an Application Load Balancer (ALB).
- **Database**: A managed RDS MySQL instance with monitoring and slow query logging enabled.
- **Security**: Granular Security Groups, Network ACLs, and IAM roles following the principle of least privilege.
- **Deployment**: AWS CodeDeploy configuration for automated application deployments.
- **Storage**: S3 buckets for assets, access logs, and deployment artifacts.
- **Monitoring**: CloudWatch Log Groups for application and database logs.
- **DNS/SSL**: Route53 and ACM integration for HTTPS termination.

## Requirements

| Tool | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads.html) | `~> 1.14.0` |
| [AWS CLI](https://aws.amazon.com/cli/) | Latest |
| [Checkov](https://www.checkov.io/) | Latest |
| AWS Account | With appropriate permissions |

## Setup & Run Commands

### 1. Initialize Terraform
This will download the required providers and initialize the S3 backend.
```powershell
terraform init
```

### 2. Plan Changes
Review the execution plan to see what resources will be created or modified.
```powershell
terraform plan -out=tfplan
```

### 3. Apply Changes
Provision the infrastructure.
```powershell
terraform apply "tfplan"
```

## Project Structure

```text
.
├── config.tf           # Terraform & Provider configuration (S3 Backend)
├── locals.tf           # Common variables and naming conventions
├── networking.tf       # VPC, Subnets, NACLs, NAT GW, VPC Endpoints
├── compute.tf          # Auto Scaling Group (ASG)
├── load_balancer.tf    # Application Load Balancer (ALB) and Target Groups
├── database.tf         # RDS MySQL instance and DB parameters
├── storage.tf          # S3 Buckets for assets, logs, and artifacts
├── iam.tf              # IAM Roles and Policies
├── dns.tf              # Route53 and ACM Certificates
├── monitoring.tf       # CloudWatch Log Groups
├── deployment.tf       # CodeDeploy application and deployment groups
├── management.tf       # AppRegistry configuration
├── security_groups.tf  # Security Group definitions
├── user-data.sh.tpl    # EC2 Bootstrap script template
└── .tflint.hcl         # TFLint configuration
```

## Scripts & Entry Points

- **`user-data.sh.tpl`**: The bootstrap script used by EC2 instances during launch to initialize the application environment.
- **Terraform Plan**: `tfplan` is the primary entry point for reviewing infrastructure changes before application.

## Environment & Variables

Configuration is primarily managed via `locals.tf`. Key parameters include:

- `environment`: Set to `dev` by default.
- `app_name`: `phase-1`
- `base_domain`: `bilalyasin.com` (Used for Route53 and ACM)
- `db_username`: `phase1_user`

### SSM Parameters
The following configuration is exported to AWS SSM Parameter Store:
- `/${environment}/${app_name}/db_config`: Database connection details (JSON).
- `/${environment}/${app_name}/s3_config`: Asset bucket name.

## Tests
- TODO: Implement infrastructure tests (e.g., using `terraform test` or Terratest).
- **Static Analysis**:
  - **TFLint**: Configured via `.tflint.hcl`. Run with `tflint`.
  - **Checkov**: Scan the execution plan for security misconfigurations:
    ```powershell
    terraform plan -out=tfplan
    terraform show -json tfplan > tfplan.json
    checkov -f tfplan.json
    ```

## License
- TODO: Define license (e.g., MIT, Apache 2.0).

## TODOs
- [ ] Add CI/CD pipeline using GitHub Actions.
- [ ] Implement automated backup validation.
- [ ] Add more granular CloudWatch Alarms.
- [ ] Define a clear branching strategy for multi-environment support (if moving beyond single-env).
