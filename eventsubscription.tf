data "aws_caller_identity" "current" {
  
}

resource "aws_sns_topic" "sns_topic" {
  name              = var.sns_name
  tags              = merge(module.mandatorytags.tags, var.tags)
  delivery_policy   = var.delivery_policy == "" ? null : file(var.delivery_policy)
}
resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.sns_topic.arn
  policy = length(var.sns_topic_policy_json) > 0 ? var.sns_topic_policy_json : data.aws_iam_policy_document.sns_topic_policy.json
}
data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = var.policy_id
  statement {
    actions = [
      "SNS:AddPermission",
      "SNS:DeleteTopic",
      "SNS:GetTopicAttributes",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:Subscribe",
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = var.identifiers
    }
    resources = [
      aws_sns_topic.sns_topic.arn,
    ]
    sid = var.stat_id
  }
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  for_each               = var.subscribers
  topic_arn              = aws_sns_topic.sns_topic.arn
  protocol               = var.subscribers[each.key].protocol == "http" ? "provide valid protocol" : var.subscribers[each.key].protocol
  endpoint               = var.subscribers[each.key].endpoint == "" ? "provide valid endpoint" : var.subscribers[each.key].endpoint
  endpoint_auto_confirms = var.subscribers[each.key].endpoint_auto_confirms
}

resource "aws_db_event_subscription" "rds" {

  name             = var.name
  sns_topic        = aws_sns_topic.sns_topic.arn
  source_ids       = var.source_ids
  source_type      = var.source_type
  event_categories = var.event_categories
  enabled          = var.enabled
  tags             = merge(module.mandatorytags.tags, var.tags)

  }
