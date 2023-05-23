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
  count = var.aws_create_iam_role ? 1 : 0
  name                  = var.iam_role_name
  description           = var.role_description
  permissions_boundary  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/antm-IAMPermissionsBoundaryForExecutionRole"
  assume_role_policy    = var.assume_role_policy == null || var.assume_role_policy == "" ? data.aws_iam_policy_document.list_services.json : var.assume_role_policy
  force_detach_policies = var.force_detach_policies 
  max_session_duration  = var.max_session_duration
  tags                  = var.tags
  dynamic "inline_policy" {
    for_each = var.inline_policy
    
    content {
        name   = inline_policy.value.name         
        policy = inline_policy.value.policy
     }
  }
  path                = var.path
  managed_policy_arns  = var.managed_policy_arns
  lifecycle {
    ignore_changes = [
      assume_role_policy
    ]
  }
}
