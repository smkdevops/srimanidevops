data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "list_services" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = var.assume_role_service_names
    }
  }
}

resource "aws_iam_role" "iamrole" {
  name                  = "${var.cluster_name}-Role"
  description           = "EKS IAM Role"
  permissions_boundary  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/antm-IAMPermissionsBoundaryForExecutionRole"
  assume_role_policy    = var.assume_role_policy == null || var.assume_role_policy == "" ? data.aws_iam_policy_document.list_services.json : var.assume_role_policy
  force_detach_policies = false
  max_session_duration  = 3600
  tags                  = var.tags
  path                  = "/"
  managed_policy_arns   = var.managed_policy_arns
}
