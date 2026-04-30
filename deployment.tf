# ==============================================================================
# CODEDEPLOY CONFIGURATION
# ==============================================================================

# Primary CodeDeploy application container for the environment
resource "aws_codedeploy_app" "this" {
  name = "${local.app_name}-${local.environment}"

  tags = local.app_registry_tag
}

# Deployment group defining how code is pushed to the Auto Scaling Group
resource "aws_codedeploy_deployment_group" "this" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = "${local.environment}-main-group"
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn

  # Link to the compute layer
  autoscaling_groups = [module.asg.autoscaling_group_name]

  # Safety: Revert to previous version if deployment fails
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  # Strategy: Update instances in-place while managing ALB traffic
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  # Target group for connection draining and health checks
  load_balancer_info {
    target_group_info {
      name = module.alb.target_groups["app-tg"].name
    }
  }

  # Rollout speed: One instance at a time
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  tags = local.app_registry_tag
}
