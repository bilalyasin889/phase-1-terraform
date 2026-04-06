data "aws_iam_policy_document" "codedeploy_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codedeploy_service_role" {
  name               = "${local.app_name}-codedeploy-service-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role.json

  tags = local.app_registry_tag
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_service_role.name
}

resource "aws_codedeploy_app" "this" {
  name = "${local.app_name}-deploy"

  tags = local.app_registry_tag
}

resource "aws_codedeploy_deployment_group" "this" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = "${local.environment}-main-group"
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn

  autoscaling_groups = [module.asg.autoscaling_group_name]

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  load_balancer_info {
    target_group_info {
      name = module.alb.target_groups["app-tg"].name
    }
  }

  deployment_config_name = "CodeDeployDefault.OneAtATime"

  tags = local.app_registry_tag
}
