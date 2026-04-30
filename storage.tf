module "s3_assets" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.10.0"

  bucket = "${local.app_name}-assets"

  versioning = {
    enabled = true
  }

  tags = local.app_registry_tag
}

module "s3_alb_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.10.0"

  bucket = "${local.app_name}-alb-access-logs"

  attach_elb_log_delivery_policy = true
  attach_lb_log_delivery_policy  = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  lifecycle_rule = [
    {
      id      = "log-retention"
      enabled = true
      expiration = {
        days = 90
      }
    }
  ]

  versioning = {
    enabled = true
  }

  tags = local.app_registry_tag
}

locals {
  ssm_s3_config = "${local.ssm_param_store_prefix}/s3_config"
}

resource "aws_ssm_parameter" "s3_config" {
  name = local.ssm_s3_config
  type = "String"

  value = module.s3_assets.s3_bucket_id

  tags = local.app_registry_tag
}



# ==============================================================================
# STORAGE FOR DEPLOYMENT ARTIFACTS
# ==============================================================================

# Secure bucket to hold revision zips and migration scripts
module "artifact_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.10.0"

  bucket = "${local.app_name}-${local.environment}-artifacts"

  # Enable versioning to allow rollbacks and audit history
  versioning = {
    enabled = true
  }

  tags = local.app_registry_tag
}

# Export the bucket ID for use in CI/CD pipelines
output "artifact_bucket_name" {
  value = module.artifact_bucket.s3_bucket_id
}
