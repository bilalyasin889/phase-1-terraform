data "aws_route53_zone" "main_zone" {
  name = local.base_domain
}

module "app_acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.3.0"

  domain_name  = local.app_domain
  subject_alternative_names = [
    local.api_domain
  ]

  zone_id      = data.aws_route53_zone.main_zone.zone_id

  validation_method = "DNS"

  wait_for_validation = true

  tags = local.app_registry_tag
}