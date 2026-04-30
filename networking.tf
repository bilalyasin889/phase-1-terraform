data "aws_availability_zones" "azs" {
  state = "available"
}

locals {
  vpc_cidr = "10.0.0.0/16"

  # number of AZs
  az_count = length(data.aws_availability_zones.azs.names)

  # public subnets /24
  public_cidrs = [
    for i in range(local.az_count) : cidrsubnet(local.vpc_cidr, 8, i)
  ]
  public_subnet_names = [
    for az in data.aws_availability_zones.azs.names :
    "${local.app_name}-public-subnet-${az}"
  ]

  # private subnets /24, offset 100
  private_cidrs = [
    for i in range(local.az_count) : cidrsubnet(local.vpc_cidr, 8, i + 100)
  ]
  private_subnet_names = [
    for az in data.aws_availability_zones.azs.names :
    "${local.app_name}-private-subnet-${az}"
  ]

  # db subnets /24, offset 200
  db_cidrs = [
    for i in range(local.az_count) : cidrsubnet(local.vpc_cidr, 8, i + 200)
  ]
  db_subnet_names = [
    for az in data.aws_availability_zones.azs.names :
    "${local.app_name}-db-subnet-${az}"
  ]
  db_subnet_group_name = "${local.app_name}-db-subnet-group"

  # Public inbound rules (Internet → ALB)
  nacl_rules_public_inbound = [
    {
      cidr_block  = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      rule_action = "allow"
      rule_number = 100
    },
    {
      cidr_block  = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      rule_action = "allow"
      rule_number = 110
    }
  ]

  # Public outbound rules (responses to Internet)
  nacl_rules_public_outbound = [
    {
      cidr_block  = "0.0.0.0/0"
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      rule_action = "allow"
      rule_number = 100
    }
  ]

  # Internal inbound rules (VPC → private/app)
  nacl_rules_internal_inbound = [
    {
      cidr_block  = local.vpc_cidr
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      rule_action = "allow"
      rule_number = 100
    }
  ]

  # DB inbound rules (private subnets → MySQL)
  nacl_rules_db_inbound = [
    for index, cidr in local.private_cidrs :
    {
      cidr_block  = cidr
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      rule_action = "allow"
      rule_number = 200 + index
    }
  ]

  # Internal outbound rules (VPC internal communication)
  nacl_rules_internal_outbound = [
    {
      cidr_block  = local.vpc_cidr
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      rule_action = "allow"
      rule_number = 100
    }
  ]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.6.0"

  name = "${local.app_name}-vpc"
  cidr = local.vpc_cidr

  create_igw = true

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true

  azs = data.aws_availability_zones.azs.names

  # Layer 1 :: Public
  public_subnet_names          = local.public_subnet_names
  public_subnets               = local.public_cidrs
  public_dedicated_network_acl = true
  public_inbound_acl_rules     = local.nacl_rules_public_inbound
  public_outbound_acl_rules    = local.nacl_rules_public_outbound

  # Layer 2 :: Private
  private_subnet_names          = local.private_subnet_names
  private_subnets               = local.private_cidrs
  private_dedicated_network_acl = true
  private_inbound_acl_rules     = local.nacl_rules_internal_inbound
  private_outbound_acl_rules    = local.nacl_rules_internal_outbound

  # Layer 3 :: Database
  database_subnet_names              = local.db_subnet_names
  database_subnets                   = local.db_cidrs
  create_database_subnet_route_table = true
  database_subnet_group_name         = local.db_subnet_group_name
  create_database_subnet_group       = true
  database_dedicated_network_acl     = true
  database_inbound_acl_rules         = local.nacl_rules_db_inbound
  database_outbound_acl_rules        = local.nacl_rules_internal_outbound

  enable_dns_support   = true
  enable_dns_hostnames = true

  # Disable management of defaults (NACL, SG, RT)
  manage_default_security_group = false
  manage_default_network_acl    = false
  manage_default_route_table    = false

  tags = local.app_registry_tag
}

# VPC endpoints
module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.6.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.app_sg.security_group_id]
  subnet_ids         = module.vpc.private_subnets

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      tags         = { Name = "s3-vpc-endpoint" }
    }
  }

  tags = local.app_registry_tag
}
