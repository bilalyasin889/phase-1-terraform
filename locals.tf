locals {
  default_tags = {
    "project" = "aws-backend-architecture-lab"
    "phase" = "1"
    "managedBy" = "terraform"
    "environment" = "dev"
  }

  app_name = "phase-1"

  base_domain = "bilalyasin.com"
  app_domain = "phase-1.${local.base_domain}"
  api_domain = "api.${local.app_domain}"
}