module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 9.2.0"

  name = "${local.app_name}-asg"

  # Scaling
  min_size         = 0
  desired_capacity = 1
  max_size         = 3

  # Instance config
  image_id          = "ami-087c9ba923d9765d8"
  instance_type     = "t4g.micro"
  ebs_optimized     = true
  enable_monitoring = false

  # Networking and Storage
  vpc_zone_identifier = module.vpc.private_subnets
  security_groups     = [module.app_sg.security_group_id]

  block_device_mappings = [
    {
      device_name = "/dev/sda1"
      ebs = {
        volume_size = 20
        volume_type = "gp3"
      }
    }
  ]

  # Health check
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # User Data
  user_data = base64encode(templatefile("${path.module}/user-data.sh.tpl", {
    log_group_name = module.app_log_group.cloudwatch_log_group_name
  }))

  # IAM role & instance profile
  create_iam_instance_profile = true
  iam_role_name               = "${local.app_name}-${local.environment}-asg-role"
  iam_role_path               = "/ec2/${local.environment}/"
  iam_role_description        = "IAM role for ${local.app_name} instances in ${local.environment} environment"
  iam_role_tags               = local.app_registry_tag

  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    AmazonS3ReadOnlyAccess       = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }

  autoscaling_group_tags = local.app_registry_tag
}
