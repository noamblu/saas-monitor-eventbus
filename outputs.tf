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

output "lambda_function_name" {
  description = "The name of the update_omnibus Lambda"
  value       = module.update_omnibus_lambda.function_name
}

output "scheduler_arn" {
  description = "The ARN of the EventBridge Schedule"
  value       = module.update_omnibus_schedule.schedule_arn
}
