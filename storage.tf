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
