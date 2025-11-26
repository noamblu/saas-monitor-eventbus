output "arn" {
  description = "The ARN of the EventBridge bus"
  value       = aws_cloudwatch_event_bus.this.arn
}

output "name" {
  description = "The name of the EventBridge bus"
  value       = aws_cloudwatch_event_bus.this.name
}
