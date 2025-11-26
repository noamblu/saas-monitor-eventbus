output "sqs_queue_arn" {
  description = "The ARN of the main SQS queue"
  value       = module.sqs_queue.queue_arn
}

output "sqs_queue_url" {
  description = "The URL of the main SQS queue"
  value       = module.sqs_queue.queue_url
}

output "sqs_dlq_arn" {
  description = "The ARN of the dead-letter queue"
  value       = module.sqs_queue.dlq_arn
}

output "sqs_dlq_url" {
  description = "The URL of the dead-letter queue"
  value       = module.sqs_queue.dlq_url
}
