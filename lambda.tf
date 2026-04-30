# ==============================================================================
# MIGRATION ENGINE (Lambda)
# ==============================================================================
resource "aws_ecr_repository" "migration_engine" {
  name                 = "${local.app_name}-migration-engine"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true

  tags = local.app_registry_tag
}

module "lambda_migration_engine" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name = "${local.app_name}-migration-engine"
  description   = "Database migration engine using Flyway"

  create_package = false

  # Use a dummy image initially to allow Terraform to complete without errors.
  image_uri    = "public.ecr.aws/lambda/python:3.11"
  package_type = "Image"

  timeout     = 300 # 5 minutes for DB migrations
  memory_size = 512

  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [module.lambda_migration_sg.security_group_id]

  environment_variables = {
    ENV = local.environment
  }

  attach_policies    = true
  number_of_policies = 3
  policies = [
    aws_iam_policy.ssm_db_config_read.arn,
    aws_iam_policy.s3_artifact_read.arn,
    aws_iam_policy.lambda_logging.arn
  ]

  logging_log_group                  = module.app_log_group.cloudwatch_log_group_name
  logging_log_format                 = "JSON"
  attach_cloudwatch_logs_policy      = false
  attach_create_log_group_permission = false

  tags = local.app_registry_tag
}