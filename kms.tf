data "aws_region" "current" {
}
data "aws_caller_identity" "current" {
}
resource "aws_kms_key" "kms-key" {
  for_each = var.create_kms_key ? toset(local.ser_name) : []
  description              = var.description
  key_usage                = "ENCRYPT_DECRYPT"
  policy                   = each.key == "uncompliant" ? "The service name is not valid. See the readme for valid service name" : data.aws_iam_policy_document.policy[each.key].json
  deletion_window_in_days  = 30
  is_enabled               = true
  enable_key_rotation      = "true"
  multi_region             = var.multi_region
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  bypass_policy_lockout_safety_check = true

  lifecycle {
    ignore_changes = [policy]
  }

  tags = merge(module.mandatory_tags.tags, var.tags)
}
resource "aws_kms_alias" "key_alias" {
  for_each = var.create_kms_key ? toset(local.ser_name) : []
  name          = "alias/${var.application}-${var.environment}-${each.key}-v2"
  target_key_id = aws_kms_key.kms-key[each.key].id

  lifecycle {
    ignore_changes = [name]
  }
}
locals {
  services = ["backup", "dms", "ssm", "ec2", "elasticfilesystem", "es", "fsx", "glue", "kinesis", "kinesisvideo", "lambda", "kafka", "redshift", "rds", "secretsmanager", "sns", "s3", "sqs", "xray", "documentdb", "dynamodb", "aurora", "athena", "eks", "elasticache", "emr", "glacier", "sagemaker", "codebuild", "cloudtrail", "codedeploy", "storagegateway", "ecr", "logs", "appsync", "appflow", "appstream", "datasync", "mq", "kendra", "lakeformation", "healthlake", "codepipeline"]
  ser_name = [for service in var.service_name : contains(local.services, lower(service)) == true ? lower(service) : "uncompliant"]
  services_list = {
    for service in local.ser_name :
    service => format("%s%s%s%s", service, ".", data.aws_region.current.name, ".amazonaws.com")...
  }
  logs = lookup(local.services_list, "logs", null) != null
  s3 = lookup(local.services_list, "s3", null) != null
  lambda = lookup(local.services_list, "lambda", null) != null
  ec2 = lookup(local.services_list, "ec2", null) != null
  sns = lookup(local.services_list, "sns", null) != null
  sqs = lookup(local.services_list, "sqs", null) != null
  dynamic_services_list = ["logs", "s3", "lambda", "ec2", "sns", "sqs"]
}
data "aws_iam_policy_document" "policy" {
  for_each = var.create_kms_key ? toset(local.ser_name) : []
  # Admin permissions
  statement {
    sid    = "Enable Access for Key Administrators"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/antm-ees-admin"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  ### Enable Terraform Role Permissions
  statement {
    sid    = "Enable Terraform Role Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OlympusVaultServiceRole"]
    }
    actions = [
      "kms:CancelKeyDeletion",
      "kms:CreateAlias",
      "kms:CreateKey",
      "kms:DeleteAlias",
      "kms:DisableKey",
      "kms:EnableKey",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:List*",
      "kms:ScheduleKeyDeletion",
      "kms:UpdateAlias",
      "kms:GetKeyRotationStatus",
      "kms:GetKeyPolicy",
      "kms:EnableKeyRotation",
      "kms:DescribeKey",
      "kms:UpdateKeyDescription",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ReplicateKey"
    ]
    resources = [
      "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*",
      "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:alias/*"
    ]
  }
  # Add S3 Permissions
  dynamic "statement" {
    for_each = local.s3 ? [1] : []
    content {
      sid    = "S3 Permissions"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt*",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
        "kms:ListGrants",
        "kms:TagResource",
        "kms:UntagResource"
      ]
      resources = [
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*",
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:alias/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${data.aws_region.current.name}.amazonaws.com","lambda.${data.aws_region.current.name}.amazonaws.com","sns.${data.aws_region.current.name}.amazonaws.com","sqs.${data.aws_region.current.name}.amazonaws.com"]
      }
    }
  }
  # Add Lambda Permissions
  dynamic "statement" {
    for_each = local.lambda ? [1] : []
    content {
      sid    = "Lambda Permissions"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt*",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
        "kms:ListGrants",
        "kms:TagResource",
        "kms:UntagResource"
      ]
      resources = [
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*",
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:alias/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${data.aws_region.current.name}.amazonaws.com","lambda.${data.aws_region.current.name}.amazonaws.com","sns.${data.aws_region.current.name}.amazonaws.com"]
      }
    }
  }  
  # Adding EC2 Permissions
  dynamic "statement" {
    for_each = local.ec2 ? [1] : []
    content {
      sid    = "EC2 Permissions"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt*",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
        "kms:ListGrants",
        "kms:TagResource",
        "kms:UntagResource"
      ]
      resources = [
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*",
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:alias/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["ec2.${data.aws_region.current.name}.amazonaws.com", "s3.${data.aws_region.current.name}.amazonaws.com","lambda.${data.aws_region.current.name}.amazonaws.com","sns.${data.aws_region.current.name}.amazonaws.com", "logs.${data.aws_region.current.name}.amazonaws.com", "sqs.${data.aws_region.current.name}.amazonaws.com", "rds.${data.aws_region.current.name}.amazonaws.com", "ssm.${data.aws_region.current.name}.amazonaws.com"]
      }
    }
  }
  # Adding SNS Permissions
  dynamic "statement" {
    for_each = local.sns ? [1] : []
    content {
      sid    = "SNS Permissions"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt*",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
        "kms:ListGrants",
        "kms:TagResource",
        "kms:UntagResource"
      ]
      resources = [
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*",
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:alias/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${data.aws_region.current.name}.amazonaws.com","lambda.${data.aws_region.current.name}.amazonaws.com","sns.${data.aws_region.current.name}.amazonaws.com", "logs.${data.aws_region.current.name}.amazonaws.com"]
      }
    }
  }
  # Adding SQS Permissions
  dynamic "statement" {
    for_each = local.sqs ? [1] : []
    content {
      sid    = "SQS Permissions"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt*",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
        "kms:ListGrants",
        "kms:TagResource",
        "kms:UntagResource"
      ]
      resources = [
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*",
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:alias/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["lambda.${data.aws_region.current.name}.amazonaws.com","sqs.${data.aws_region.current.name}.amazonaws.com", "sns.${data.aws_region.current.name}.amazonaws.com"]
      }
    }
  }
  # Cloudwatch Permissions
  dynamic "statement" {
    for_each = local.logs ? [1] : []
    content {
      sid    = "Cloudwatch Permissions1"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt*",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
        "kms:ListGrants",
        "kms:TagResource",
        "kms:UntagResource"
      ]
      resources = [
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*",
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:alias/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["logs.${data.aws_region.current.name}.amazonaws.com"]
      }
    }
  }  
  dynamic "statement" {
    for_each = local.logs ? [1] : []
    content {
      sid    = "Cloudwatch Permissions2"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
      }
      actions = [
      "kms:Describe*",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*"
      ]
      resources = ["*"]
      condition {
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
      }
    }
  } 
  # Add Permissions for except dynamic services
  dynamic "statement" {
    for_each = contains(local.dynamic_services_list, each.key) ? [] : [1]
    content {
      sid    = "developer role permissions"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt*",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
        "kms:ListGrants",
        "kms:TagResource",
        "kms:UntagResource"
      ]
      resources = [
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*",
        "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:alias/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = local.services_list[each.key]
      }
    }
  }
  # Enable view permissions of the key
  statement {
    sid    = "Enable view KMS key details in console"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:List*",
      "kms:GetKeyRotationStatus",
      "kms:GetKeyPolicy",
      "kms:DescribeKey"
    ]
    resources = [
      "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*",
      "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:alias/*"
    ]
  }
  # Restrict post-key-creation policy modification
  statement {
    sid    = "Restrict post-key-creation policy modification"
    effect = "Deny"
    not_principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/antm-ees-admin"]
    }
    actions = [
      "kms:PutKeyPolicy"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:BypassPolicyLockoutSafetyCheck"
      values = ["true"]
    }
  }
  # Allow attachment of persistent resources
  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RetireGrant",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  } 
}
