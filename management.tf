# tflint-ignore: aws_resource_missing_tags
resource "aws_servicecatalogappregistry_application" "this" {
  name        = local.app_name
  description = "Application container for ${local.app_name}"
}

locals {
  app_registry_tag = aws_servicecatalogappregistry_application.this.application_tag
}