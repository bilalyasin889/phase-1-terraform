locals {
  default_tags = {
    "project"     = "aws-backend-architecture-lab"
    "phase"       = "1"
    "managedBy"   = "terraform"
    "environment" = local.environment
  }

  environment = "dev"

  app_name = "phase-1"

  base_domain = "bilalyasin.com"
  app_domain  = "phase-1.${local.base_domain}"
  api_domain  = "api.${local.app_domain}"

  db_name     = "${local.app_name}-dev-db"
  db_username = "phase1_user"
}