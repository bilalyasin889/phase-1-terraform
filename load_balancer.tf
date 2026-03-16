module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.5.0"

  name    = "${local.app_name}-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  create_security_group = false
  security_groups       = [module.alb_sg.security_group_id]

  access_logs = {
    bucket = module.s3_alb_logs.s3_bucket_id
    prefix = "${local.app_name}-alb"
  }

  route53_records = {
    A = {
      name    = local.api_domain
      zone_id = data.aws_route53_zone.main_zone.zone_id
      type    = "A"
    }
  }

  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.app_acm.acm_certificate_arn

      fixed_response = {
        content_type = "text/plain"
        message_body = "Not found."
        status_code  = "404"
      }

      rules = {
        api-routing = {
          priority = 1
          actions = [{
            forward = {
              target_group_key = "app-tg"
            }
          }]
          conditions = [{
            host_header = {
              values = [local.api_domain]
            }
          }]
        }
      }
    }
  }

  target_groups = {
    app-tg = {
      name_prefix = "app-"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"

      create_attachment = false

      health_check = {
        enabled             = true
        path                = "/health"
        interval            = 30
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        matcher             = "200"
      }
    }
  }

  tags = local.app_registry_tag
}
