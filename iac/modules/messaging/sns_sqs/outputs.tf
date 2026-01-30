output "sns_topic_arn" {
  value = aws_sns_topic.events.arn
}

output "notifications_queue_url" {
  value = aws_sqs_queue.notifications_queue.id
}

output "notifications_queue_arn" {
  value = aws_sqs_queue.notifications_queue.arn
}

output "notifications_dlq_arn" {
  value = aws_sqs_queue.notifications_dlq.arn
}

output "inventory_queue_url" {
  value = aws_sqs_queue.inventory_queue.id
}

output "inventory_queue_arn" {
  value = aws_sqs_queue.inventory_queue.arn
}

output "inventory_dlq_arn" {
  value = aws_sqs_queue.inventory_dlq.arn
}
