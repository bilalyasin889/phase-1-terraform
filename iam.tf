# ==========================================
# S3 BUCKET POLICIES
# ==========================================

# Access to the Artifact Bucket (Read-only for EC2/Lambda)
resource "aws_iam_policy" "s3_artifact_read" {
  name        = "${local.app_name}-S3ArtifactRead"
  description = "Allows pulling deployment zips and migration scripts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        module.artifact_bucket.s3_bucket_arn,
        "${module.artifact_bucket.s3_bucket_arn}/*"
      ]
    }]
  })

  tags = local.app_registry_tag
}

# Access to the Artifact Bucket (Upload for GitHub Actions)
resource "aws_iam_policy" "s3_artifact_upload" {
  name        = "${local.app_name}-S3ArtifactUpload"
  description = "Allows CI/CD to upload artifacts and scripts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:PutObject", "s3:GetBucketLocation", "s3:ListBucket"]
      Resource = [
        module.artifact_bucket.s3_bucket_arn,
        "${module.artifact_bucket.s3_bucket_arn}/*"
      ]
    }]
  })

  tags = local.app_registry_tag
}

# Access to the Assets Bucket (Full Read/Write for Compute Layer)
resource "aws_iam_policy" "s3_assets_full_access" {
  name        = "${local.app_name}-S3AssetsFullAccess"
  description = "Allows application to manage user assets and presigned URLs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
        Resource = "${module.s3_assets.s3_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = module.s3_assets.s3_bucket_arn
      }
    ]
  })

  tags = local.app_registry_tag
}

# ==========================================
# SSM PARAMETER POLICIES
# ==========================================

# DB Configuration (Includes KMS decryption for SecureString)
resource "aws_iam_policy" "ssm_db_config_read" {
  name        = "${local.app_name}-SSMDBConfigRead"
  description = "Allows reading and decrypting database credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = [aws_ssm_parameter.db_config.arn]
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "*"
      }
    ]
  })

  tags = local.app_registry_tag
}

# S3 Configuration (Plain text ID)
resource "aws_iam_policy" "ssm_s3_config_read" {
  name        = "${local.app_name}-SSMS3ConfigRead"
  description = "Allows reading the Assets bucket name/ID from SSM"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = [aws_ssm_parameter.s3_config.arn]
    }]
  })

  tags = local.app_registry_tag
}

# ==========================================
# LAMBDA POLICIES
# ==========================================
resource "aws_iam_policy" "lambda_logging" {
  name        = "${local.app_name}-lambda-logging-scoped"
  description = "Allows Lambda to write logs strictly to the shared app log group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        # Narrowing the scope to exactly one log group to pass Checkov CKV_AWS_355
        Resource = "${module.app_log_group.cloudwatch_log_group_arn}:*"
      }
    ]
  })

  tags = local.app_registry_tag
}

# ==========================================
# COMPUTATION & ORCHESTRATION POLICIES
# ==========================================

# CodeDeploy Execution (Triggering deployments from GitHub)
resource "aws_iam_policy" "codedeploy_trigger" {
  name        = "${local.app_name}-CodeDeployTrigger"
  description = "Allows GitHub Actions to start CodeDeploy deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ]
      Resource = [
        aws_codedeploy_deployment_group.this.arn,
        aws_codedeploy_app.this.arn
      ]
    }]
  })

  tags = local.app_registry_tag
}

# Lambda Management (Updating Migration Engine code)
resource "aws_iam_policy" "migration_lambda_mgmt" {
  name        = "${local.app_name}-MigrationLambdaMgmt"
  description = "Allows CI/CD to update the migration engine Lambda image"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:UpdateFunctionCode", "lambda:GetFunction"]
      Resource = [module.lambda_migration_engine.lambda_function_arn]
    }]
  })

  tags = local.app_registry_tag
}

# Lambda Execution (Triggering the Migration Engine)
resource "aws_iam_policy" "migration_lambda_invoke" {
  name        = "${local.app_name}-MigrationLambdaInvoke"
  description = "Allows triggering the database migration Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = [module.lambda_migration_engine.lambda_function_arn]
    }]
  })

  tags = local.app_registry_tag
}

# ECR Management (Pushing images)
resource "aws_iam_policy" "ecr_push" {
  name        = "${local.app_name}-ECRPush"
  description = "Allows pushing Docker images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = [aws_ecr_repository.migration_engine.arn]
      }
    ]
  })

  tags = local.app_registry_tag
}

# ==========================================
# GITHUB OIDC ROLES
# ==========================================

module "github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "~> 5.0"
  tags    = local.app_registry_tag
}

# Role for Application Repos
module "gh_role_apps" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.0"
  name    = "${local.app_name}-gh-apps-deployer"

  subjects = [
    "bilalyasin889/data-service:*",
    "bilalyasin889/storage-service:*",
    "bilalyasin889/nginx-config:*"
  ]

  policies = {
    S3Artifacts = aws_iam_policy.s3_artifact_upload.arn
    CodeDeploy  = aws_iam_policy.codedeploy_trigger.arn
  }
}

# Role for the Migration Engine Repo
module "gh_role_engine" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.0"
  name    = "${local.app_name}-gh-engine-manager"

  subjects = ["bilalyasin889/migration-engine:*"]

  policies = {
    ECR    = aws_iam_policy.ecr_push.arn
    Lambda = aws_iam_policy.migration_lambda_mgmt.arn
  }
}

# Role for the Database Config Repo
module "gh_role_db_config" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.0"
  name    = "${local.app_name}-gh-db-config-runner"

  subjects = ["bilalyasin889/database-config:*"]

  policies = {
    S3Artifacts = aws_iam_policy.s3_artifact_upload.arn
    Invoke      = aws_iam_policy.migration_lambda_invoke.arn
  }
}

# ==========================================
# CODEDEPLOY SERVICE ROLE
# ==========================================

data "aws_iam_policy_document" "codedeploy_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy_service_role" {
  name               = "${local.app_name}-codedeploy-service-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role.json

  tags = local.app_registry_tag
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_service_role.name
}