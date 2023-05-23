data "aws_kms_key" "kms_validation"{
  key_id = var.kms_master_key_id
}

resource "aws_sqs_queue" "sqsqueue" {
  name = var.sqs_queue_name

  visibility_timeout_seconds  = var.visibility_timeout_seconds
  message_retention_seconds   = var.message_retention_seconds
  max_message_size            = var.max_message_size
  delay_seconds               = var.delay_seconds
  receive_wait_time_seconds   = var.receive_wait_time_seconds
  policy                      = var.policy == "" ? "": var.policy
  redrive_policy              = var.redrive_policy == "" ? "": file(var.redrive_policy)
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.content_based_deduplication

  kms_master_key_id                 = data.aws_kms_key.kms_validation.id == null ? "KMS Key is not valid" : var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds

  tags = var.tags
}

