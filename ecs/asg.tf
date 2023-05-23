resource "aws_autoscaling_group" "ecs-autoscaling-group" {
  count            = var.launch_type == "EC2" ? 1 : 0
  name             = var.asg_name
  max_size         = var.max_size
  min_size         = var.min_size
  default_cooldown = var.default_cooldown

  launch_configuration        = aws_launch_configuration.ecs-launch-config[0].name
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type
  desired_capacity          = var.desired_capacity
  force_delete              = var.force_delete
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [var.target_group_arn]
  termination_policies      = var.termination_policies
  suspended_processes       = var.suspended_processes
  placement_group           = var.placement_group
  enabled_metrics           = var.enabled_metrics
  metrics_granularity       = var.metrics_granularity
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  min_elb_capacity          = var.min_elb_capacity
  protect_from_scale_in     = var.protect_from_scale_in
  service_linked_role_arn   = var.service_linked_role_arn
  
    dynamic "tag" {
    for_each = merge(var.tags, module.mandatory_tags.tags)
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    } 
   }
}

