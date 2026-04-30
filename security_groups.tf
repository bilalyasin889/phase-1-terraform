# ==============================================================================
# LOAD BALANCER SECURITY
# ==============================================================================
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3.1"

  name        = "${local.app_name}-alb-sg"
  description = "Public ingress for HTTP/HTTPS; forwards to application tier"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Restrict outbound to App tier only"
      source_security_group_id = module.app_sg.security_group_id
    }
  ]

  tags = local.app_registry_tag
}

# ==============================================================================
# APPLICATION SECURITY
# ==============================================================================
module "app_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3.1"

  name        = "${local.app_name}-app-sg"
  description = "Application server: Ingress from ALB, Egress to RDS and Public APIs"
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Accept routed traffic from ALB"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]

  egress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      description              = "Scoped egress to Database tier"
      source_security_group_id = module.db_sg.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS for package management and AWS API calls"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.app_registry_tag
}

# ==============================================================================
# MIGRATION ENGINE SECURITY
# ==============================================================================
module "lambda_migration_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3.1"

  name        = "${local.app_name}-migration-sg"
  description = "Migration Lambda: Outbound access for AWS services"
  vpc_id      = module.vpc.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS for SSM Parameter Store and S3 Artifacts"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      description              = "Allow Lambda to execute SQL on RDS"
      source_security_group_id = module.db_sg.security_group_id
    }
  ]

  tags = local.app_registry_tag
}

# ==============================================================================
# DATABASE SECURITY
# ==============================================================================
module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.3.1"

  name        = "${local.app_name}-db-sg"
  description = "Database: SQL access strictly from App and Migration compute"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "mysql-tcp"
      source_security_group_id = module.app_sg.security_group_id
      description              = "MySQL from App Instances"
    },
    {
      rule                     = "mysql-tcp"
      source_security_group_id = module.lambda_migration_sg.security_group_id
      description              = "MySQL from Migration Lambda"
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 2

  tags = local.app_registry_tag
}