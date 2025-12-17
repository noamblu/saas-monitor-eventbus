output "schedule_arn" {
  description = "ARN of the EventBridge Schedule"
  value       = aws_scheduler_schedule.this.arn
}

output "role_arn" {
  description = "ARN of the IAM role created for the scheduler"
  value       = aws_iam_role.scheduler_role.arn
}
