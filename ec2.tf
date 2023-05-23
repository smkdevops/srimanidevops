data "aws_kms_key" "this" {
  key_id = var.kms_key_id
}


resource "aws_instance" "anthmec2" {
  count                                = var.number_of_instances
  ami                                  = var.instance_ami
  instance_type                        = var.instance_type
  iam_instance_profile                 = var.iam_instance_profile
  associate_public_ip_address          = length(var.network_interface_id) != 0 ? null : false
  vpc_security_group_ids               = length(var.network_interface_id) != 0 ? null : var.vpc_security_group_ids
  monitoring                           = var.monitoring
  subnet_id                            = length(var.network_interface_id) != 0 ? null : element(var.subnet_ids, count.index)
  source_dest_check                    = length(var.network_interface_id) != 0 ? null : var.source_dest_check
  tenancy                              = var.tenancy
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  user_data                            = var.user_data
  disable_api_termination              = var.disable_api_termination
  host_id                              = var.host_id

  root_block_device {
    volume_size           = var.root_volume_size
    delete_on_termination = var.delete_on_termination
    encrypted             = true
    kms_key_id            = data.aws_kms_key.this.id == null ? "KMS Key is not valid" : var.kms_key_id
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device != null ? var.ebs_block_device : []
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = true
      iops                  = lookup(ebs_block_device.value, "iops", null)
      kms_key_id            = data.aws_kms_key.this.id == null ? "KMS Key is not valid" : var.kms_key_id
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  dynamic "network_interface" {
    for_each = length(var.network_interface_id) == 0 ? [] : [1]
    content {
      device_index          = 0
      network_interface_id  = element(var.network_interface_id, count.index)
      delete_on_termination = var.delete_on_termination_eni
    }
  }

  lifecycle {
    ignore_changes = [
      private_ip,
      root_block_device,
      ebs_block_device,
      ami,
    ]
  }
  volume_tags = merge(module.mandatorytags.tags, var.tags)
  tags        = merge(module.mandatorytags.tags, { "Name" = length("${var.instance_name}") <= 0 ? "${module.mandatorytags.tags["application-name"]}-${module.mandatorytags.tags["environment"]}-${module.mandatorytags.tags["resource-type"]}${count.index + 1}" : "${var.instance_name}${count.index + 1}" })
}
