data "aws_kms_key" "this" {
  count  = var.create_s3_bucket == true ? 1 : 0
  key_id = var.aws_kms_key_arn
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  endpoint = data.aws_region.current.name == "us-east-1" ? "vpce-0c65760352332dd5a" : "vpce-0157fc5f0d4d2b003"
}

resource "aws_s3_bucket" "private_bucket" {
  count  = var.create_s3_bucket == true ? 1 : 0
  bucket = var.bucket
  dynamic "object_lock_configuration" {
    for_each = length(var.object_lock_configuration) != 0 ? [var.object_lock_configuration] : []
    content {
      object_lock_enabled = object_lock_configuration.value.object_lock_enabled
    }
  }

  tags          = merge(module.mandatory_data_tags.tags, module.mandatorytags.tags, var.tags)
  force_destroy = var.force_destroy

  lifecycle {
    ignore_changes = [
      replication_configuration
    ]
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_configuration" {
  count                 = var.create_s3_bucket == true ? 1 : 0
  bucket                = element(concat(aws_s3_bucket.private_bucket.*.id, [""]), 0)
  expected_bucket_owner = data.aws_caller_identity.current.account_id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = data.aws_kms_key.this[0].id == null ? "KMS Key is not valid" : var.aws_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = var.bucket_key_enabled
  }

}

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  count                 = var.create_s3_bucket == true ? 1 : 0
  bucket                = element(concat(aws_s3_bucket.private_bucket.*.id, [""]), 0)
  expected_bucket_owner = data.aws_caller_identity.current.account_id
  acl                   = "private"
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  count  = var.create_s3_bucket == true ? 1 : 0
  bucket = element(concat(aws_s3_bucket.private_bucket.*.id, [""]), 0)

  # Block new public ACLs and uploading public objects
  block_public_acls = true

  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = true

  # Block new public bucket policies
  block_public_policy = true

  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "s3_bucket_logging" {
  count                 = var.create_aws_s3_bucket_logging == true ? 1 : 0
  bucket                = element(concat(aws_s3_bucket.private_bucket.*.id, [""]), 0)
  expected_bucket_owner = data.aws_caller_identity.current.account_id
  target_bucket         = "antm-${data.aws_caller_identity.current.account_id}-serveraccesslogging-${data.aws_region.current.name}"
  target_prefix         = "log-${var.bucket}/"
  dynamic "target_grant" {
    for_each = length(var.target_grant) != 0 ? [var.target_grant] : []
    content {
      permission = lookup(target_grant.value, "permission", null)
      dynamic "grantee" {
        for_each = lookup(target_grant.value, "grantee", null)

        content {
          email_address = lookup(grantee.value, "email_address", null)
          id            = lookup(grantee.value, "id", null)
          type          = lookup(grantee.value, "type", null)
          uri           = lookup(grantee.value, " uri", null)
        }
      }
    }
  }
}



resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  count  = var.create_s3_bucket_versioning == true ? 1 : 0
  bucket = element(concat(aws_s3_bucket.private_bucket.*.id, [""]), 0)
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = var.mfa_delete
  }
  mfa                   = var.mfa
  expected_bucket_owner = data.aws_caller_identity.current.account_id
}


resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle_configuration" {
  count                 = var.create_aws_s3_lifecycle_configuration == true ? 1 : 0
  bucket                = var.bucket
  expected_bucket_owner = data.aws_caller_identity.current.account_id
  rule {
    id = "${var.bucket}_lifecycle_configuration"
    abort_incomplete_multipart_upload {
      days_after_initiation = var.days_after_initiation
    }
    expiration {
      date                         = var.expiration_date
      days                         = var.expiration_days
      expired_object_delete_marker = "true"
    }
    dynamic "filter" {
      for_each = var.filter_lifecycle_configuration

      content {
        object_size_greater_than = lookup(filter.value, "object_size_greater_than", null)
        object_size_less_than    = lookup(filter.value, "object_size_less_than", null)

        dynamic "and" {
          for_each = lookup(filter.value, "and", null)
          content {
            prefix = lookup(and.value, "prefix", null)
            tags   = lookup(and.value, "tags", null)
          }
        }
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.noncurrent_version_expiration
      content {
        newer_noncurrent_versions = lookup(noncurrent_version_expiration.value, "newer_noncurrent_versions", null)
        noncurrent_days           = lookup(noncurrent_version_expiration.value, "noncurrent_days", null)
      }
    }

    dynamic "noncurrent_version_transition" {
      for_each = var.noncurrent_version_transition
      content {
        noncurrent_days           = lookup(noncurrent_version_transition.value, "noncurrent_days", null)
        storage_class             = noncurrent_version_transition.value.storage_class
        newer_noncurrent_versions = lookup(noncurrent_version_transition.value, "newer_noncurrent_versions", null)
      }
    }
    status = "Enabled"
    dynamic "transition" {
      for_each = var.transition
      content {
        date          = lookup(transition.value, "date", null)
        days          = transition.value.days
        storage_class = transition.value.storage_class
      }
    }
  }
  lifecycle {
    ignore_changes = [rule]
  }
}

resource "aws_s3_bucket_replication_configuration" "replication_configuration" {
  count  = var.create_s3_replication_configuration == true ? 1 : 0
  bucket = var.bucket
  role   = var.role
  dynamic "rule" {
    for_each = var.rule
    content {
      status   = rule.value.status
      id       = "${var.bucket}_replication_configuration"
   
      # dynamic "prefix" {
      #   for_each = length(keys(lookup(rule.value, "prefix", {}))) == 0 ? [] : [lookup(rule.value, "prefix", {})]
      #   content {
      #     status = prefix.value.status
      #   }
      # }

      # dynamic "priority" {
      #   for_each = length(keys(lookup(rule.value, "priority", {}))) == 0 ? [] : [lookup(rule.value, "priority", {})]
      #   content {
      #     status = priority.value.status
      #   }
      # }

      dynamic "delete_marker_replication" {
        for_each = length(keys(lookup(rule.value, "delete_marker_replication", {}))) == 0 ? [] : [lookup(rule.value, "delete_marker_replication", {})]
        content {
          status = delete_marker_replication.value.status
        }
      }

      dynamic "destination" {
        for_each = length(keys(lookup(rule.value, "destination", {}))) == 0 ? [] : [lookup(rule.value, "destination", {})]
        content {
          bucket        = destination.value.bucket
          storage_class = lookup(destination.value, "storage_class", null)
          account = data.aws_caller_identity.current.account_id
          dynamic "encryption_configuration" {
            for_each = length(keys(lookup(destination.value, "encryption_configuration", {}))) == 0 ? [] : [lookup(destination.value, "encryption_configuration", {})]
            content {
              replica_kms_key_id = encryption_configuration.value.replica_kms_key_id
            }
          }
      
          dynamic "access_control_translation" {
            for_each = length(keys(lookup(destination.value, "access_control_translation", {}))) == 0 ? [] : [lookup(destination.value, "access_control_translation", {})]

            content {
              owner = access_control_translation.value.owner
            }
          }
          dynamic "metrics" {
            for_each = length(keys(lookup(destination.value, "metrics", {}))) == 0 ? [] : [lookup(destination.value, "metrics", {})]
            content {
              dynamic "event_threshold" {
                for_each = lookup(metrics.value, "event_threshold", null)
                content {
                  minutes = event_threshold.value.minutes
                }
              }
              status = lookup(metrics.value, "status", null)
            }
          }

          dynamic "replication_time" {
            for_each = length(keys(lookup(destination.value, "replication_time", {}))) == 0 ? [] : [lookup(destination.value, "replication_time", {})]
            content {
              status = replication_time.value.status
              time {
                minutes = time.value.minutes
                    }
                  }
                }
        }
      }          
      dynamic "existing_object_replication"{
        for_each = length(keys(lookup(rule.value, "existing_object_replication", {}))) == 0 ? [] : [lookup(rule.value, "existing_object_replication", {})]
        content {
          status = var.existing_object_replication_status
        }
      }

      dynamic "filter" {
        for_each = length(keys(lookup(rule.value, "filter", {}))) == 0 ? [] : [lookup(rule.value, "filter", {})]
        #for_each = var.filter_rules
        content {
          dynamic "and" {
            for_each = lookup(filter.value, "and", null)
            content {
              prefix = lookup(and.value, "prefix", null)
              tags   = lookup(and.value, "tags", null)
            }
          }
          prefix = lookup(filter.value, "prefix", null)
          dynamic "tag" {
            for_each = lookup(filter.value, "tag", {})
            content {
              key   = lookup(tag.value, "key", null)
              value = lookup(tag.value, "value", null)
            }
          }
        }
      }
      dynamic "source_selection_criteria" {
        for_each = length(keys(lookup(rule.value, "source_selection_criteria", {}))) == 0 ? [] : [lookup(rule.value, "source_selection_criteria", {})]
        content {
          dynamic "sse_kms_encrypted_objects" {
            for_each = length(keys(lookup(source_selection_criteria.value, "sse_kms_encrypted_objects", {}))) == 0 ? [] : [lookup(source_selection_criteria.value, "sse_kms_encrypted_objects", {})]
            content {
              status = sse_kms_encrypted_objects.value.status
            }
          }
          dynamic "replica_modifications" {
            for_each = length(keys(lookup(source_selection_criteria.value, "replica_modifications", {}))) == 0 ? [] : [lookup(source_selection_criteria.value, "replica_modifications", {})]
            content {
              status = replica_modifications.value.status
              }
          }
        }
      }
    }
  }
}
         
       
resource "aws_s3_bucket_policy" "bucket_policy" {
  count  = var.create_s3_bucket == true ? 1 : 0
  bucket = element(concat(aws_s3_bucket.private_bucket.*.id, [""]), 0)
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}
data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    sid    = "Access-to-specific-VPCE-only"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket}",
      "arn:aws:s3:::${var.bucket}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [local.endpoint]
    }
    condition {
      test     = "StringNotLike"
      variable = "aws:PrincipalARN"
      values   = ["arn:aws:iam::*:role/OlympusVaultServiceRole", "arn:aws:iam::*:role/antm-sec", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/antm-cloudeng"]
    }
  }
}

