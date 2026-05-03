locals {
  github_secrets = {
    "storage-service" = {
      AWS_ROLE_ARN         = module.gh_role_apps.arn
      AWS_REGION           = local.region
      ARTIFACT_BUCKET_NAME = module.artifact_bucket.s3_bucket_id
      DEPLOYMENT_APP_NAME  = aws_codedeploy_app.this.name
      DEPLOYMENT_GROUP     = aws_codedeploy_deployment_group.this.deployment_group_name
    }
    "data-service" = {
      AWS_ROLE_ARN         = module.gh_role_apps.arn
      AWS_REGION           = local.region
      ARTIFACT_BUCKET_NAME = module.artifact_bucket.s3_bucket_id
      DEPLOYMENT_APP_NAME  = aws_codedeploy_app.this.name
      DEPLOYMENT_GROUP     = aws_codedeploy_deployment_group.this.deployment_group_name
    }
    "nginx-config" = {
      AWS_ROLE_ARN         = module.gh_role_apps.arn
      AWS_REGION           = local.region
      ARTIFACT_BUCKET_NAME = module.artifact_bucket.s3_bucket_id
      DEPLOYMENT_APP_NAME  = aws_codedeploy_app.this.name
      DEPLOYMENT_GROUP     = aws_codedeploy_deployment_group.this.deployment_group_name
    }
    "migration-engine" = {
      AWS_ROLE_ARN         = module.gh_role_engine.arn
      AWS_REGION           = local.region
      ARTIFACT_BUCKET_NAME = module.artifact_bucket.s3_bucket_id
      ECR_REPOSITORY_NAME  = aws_ecr_repository.migration_engine.name
      LAMBDA_FUNCTION_NAME = module.lambda_migration_engine.lambda_function_name
    }
    "database-config" = {
      AWS_ROLE_ARN         = module.gh_role_db_config.arn
      AWS_REGION           = local.region
      ARTIFACT_BUCKET_NAME = module.artifact_bucket.s3_bucket_id
      LAMBDA_FUNCTION_NAME = module.lambda_migration_engine.lambda_function_name
    }
  }

  # Flatten to a single map keyed by "repo:SECRET_NAME" for for_each
  github_secrets_flat = {
    for entry in flatten([
      for repo, secrets in local.github_secrets : [
        for secret_name, secret_value in secrets : {
          key   = "${repo}:${secret_name}"
          repo  = repo
          name  = secret_name
          value = secret_value
        }
      ]
    ]) : entry.key => entry
  }
}

resource "github_actions_environment_secret" "secrets" {
  for_each    = local.github_secrets_flat
  repository  = each.value.repo
  environment = local.environment
  secret_name = each.value.name
  value       = each.value.value
}
