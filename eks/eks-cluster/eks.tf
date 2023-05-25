resource "aws_cloudwatch_log_group" "eks_cloud_watch_log_group" {
  count             = length(var.cluster_enabled_log_types) > 0 ? 1 : 0
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_in_days
  skip_destroy      = var.cluster_log_skip_destroy
  kms_key_id        = var.cluster_log_kms_key_id == "" ? aws_kms_key.kms_key_cwl.arn : var.cluster_log_kms_key_id
  tags              = var.tags
}

resource "aws_eks_cluster" "eks_cluster" {
  name                      = var.cluster_name
  enabled_cluster_log_types = var.cluster_enabled_log_types
  role_arn                  = var.role_arn == null ? aws_iam_role.iamrole.arn : var.role_arn
  version                   = var.cluster_version == "" ? null : var.cluster_version
  tags                      = var.tags

  vpc_config {
    security_group_ids      = [aws_security_group.security-group-cluster.id]
    subnet_ids              = var.subnet_ids == null ? data.aws_subnets.private.ids : var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  timeouts {
    create = var.cluster_create_timeout
    delete = var.cluster_delete_timeout
  }

  encryption_config {
    provider {
      key_arn = var.cluster_kms_key_id == "" ? aws_kms_key.kms_key_cluster.arn : var.cluster_kms_key_id
    }
    resources = ["secrets"]
  }


  depends_on = [aws_cloudwatch_log_group.eks_cloud_watch_log_group, aws_security_group_rule.cluster-ingress-workstation-https]
}
