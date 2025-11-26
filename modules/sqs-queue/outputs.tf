output "queue_arn" {
  description = "The ARN of the main SQS queue"
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "The URL of the main SQS queue"
  value       = aws_sqs_queue.this.url
}

output "dlq_arn" {
  description = "The ARN of the dead-letter queue"
  value       = var.dlq_config.enabled ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_url" {
  description = "The URL of the dead-letter queue"
  value       = var.dlq_config.enabled ? aws_sqs_queue.dlq[0].url : null
}
