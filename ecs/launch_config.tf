resource "aws_launch_configuration" "ecs-launch-config" {
  count                       = var.launch_type == "EC2" ? 1 : 0
  name                        = var.launch_config_name
  image_id                    = var.image_id
  instance_type               = var.instance_type
  iam_instance_profile        = var.iam_instance_profile
  spot_price                  = var.spot_price
  placement_tenancy           = var.spot_price == "" ? var.placement_tenancy : ""
  security_groups             = var.security_group_ids
  associate_public_ip_address = false
  key_name                    = var.ecs_key_pair_name
  user_data                   = file(var.user_data)
  enable_monitoring           = var.enable_monitoring
  ebs_optimized               = var.ebs_optimized

  
    dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "snapshot_id", null) == null ? "true" : null
      iops                  = lookup(ebs_block_device.value, "iops", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }
  
  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
      encrypted             = "true"
    }
  }
  
  lifecycle {
    create_before_destroy = "true"
  }
}

