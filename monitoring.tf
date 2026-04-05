module "app_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "~> 3.0"

  name              = "${local.app_name}-lg"
  retention_in_days = 30

  tags = local.app_registry_tag
}

