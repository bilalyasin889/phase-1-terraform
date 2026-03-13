module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.10.0"

  bucket = "${local.app_name}-assets"

  versioning = {
    enabled = true
  }

  tags = local.app_registry_tag
}