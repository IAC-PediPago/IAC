############################
# SNS Topic (event bus simple)
############################
resource "aws_sns_topic" "events" {
  name = "${var.name_prefix}-events"
  tags = var.tags
}

############################
# SQS Queues + DLQ
############################
resource "aws_sqs_queue" "notifications_dlq" {
  name                      = "${var.name_prefix}-notifications-dlq"
  message_retention_seconds = 1209600 # 14 días
  tags                      = var.tags
}

resource "aws_sqs_queue" "inventory_dlq" {
  name                      = "${var.name_prefix}-inventory-dlq"
  message_retention_seconds = 1209600
  tags                      = var.tags
}

resource "aws_sqs_queue" "notifications_queue" {
  name                       = "${var.name_prefix}-notifications-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600 # 4 días

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = 5
  })

  tags = var.tags
}

resource "aws_sqs_queue" "inventory_queue" {
  name                       = "${var.name_prefix}-inventory-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.inventory_dlq.arn
    maxReceiveCount     = 5
  })

  tags = var.tags
}

############################
# SNS -> SQS Subscriptions
############################
resource "aws_sns_topic_subscription" "notifications_sub" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notifications_queue.arn
}

resource "aws_sns_topic_subscription" "inventory_sub" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.inventory_queue.arn
}

############################
# Policies: permitir que SNS publique en cada cola
############################
data "aws_iam_policy_document" "notifications_queue_policy" {
  statement {
    sid     = "AllowSNSSendMessage"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [aws_sqs_queue.notifications_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.events.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "notifications_queue_policy" {
  queue_url = aws_sqs_queue.notifications_queue.id
  policy    = data.aws_iam_policy_document.notifications_queue_policy.json
}

data "aws_iam_policy_document" "inventory_queue_policy" {
  statement {
    sid     = "AllowSNSSendMessage"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [aws_sqs_queue.inventory_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.events.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "inventory_queue_policy" {
  queue_url = aws_sqs_queue.inventory_queue.id
  policy    = data.aws_iam_policy_document.inventory_queue_policy.json
}
