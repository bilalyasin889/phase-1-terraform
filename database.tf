ephemeral "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.1.0"

  identifier = "${local.app_name}-db"

  # Networking
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_sg.security_group_id]

  # DB version
  engine               = "mysql"
  engine_version       = "8.4.8"
  major_engine_version = "8.4"

  # Compute and storage
  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"
  storage_encrypted     = true

  # DB setup
  port                = "3306"
  db_name             = local.db_name
  username            = local.db_username
  password_wo         = ephemeral.random_password.db_password.result
  password_wo_version = 1 # The 'version' prevents it from rotating every time.

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-03:30"

  skip_final_snapshot              = false
  final_snapshot_identifier_prefix = "${local.app_name}-final-absolution"

  deletion_protection = true

  # Monitoring
  monitoring_interval    = "30"
  create_monitoring_role = true

  create_db_parameter_group   = true
  family                      = "mysql8.4"
  parameter_group_name        = "${local.app_name}-mysql84"
  parameter_group_description = "Managed by Terraform - enables slow query logging"
  parameters = [
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "long_query_time"
      value = "2"
    },
    {
      name  = "log_output"
      value = "FILE"
    }
  ]

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_class             = "INFREQUENT_ACCESS"
  cloudwatch_log_group_retention_in_days = 7
  cloudwatch_log_group_tags              = local.app_registry_tag

  tags = local.app_registry_tag
}

locals {
  ssm_db_config = "${local.ssm_param_store_prefix}/db_config"
}

resource "aws_ssm_parameter" "db_config" {
  name = local.ssm_db_config
  type = "SecureString"

  value_wo = jsonencode({
    host     = module.db.db_instance_address
    port     = module.db.db_instance_port
    user     = local.db_username
    password = ephemeral.random_password.db_password.result
    dbname   = module.db.db_instance_name
  })

  value_wo_version = 1

  tags = local.app_registry_tag
}
