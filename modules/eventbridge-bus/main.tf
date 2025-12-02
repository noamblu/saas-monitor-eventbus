resource "aws_cloudwatch_event_bus" "this" {
  name = var.name
  tags = var.tags
}

resource "aws_cloudwatch_event_archive" "this" {
  count = var.archive_config.enabled ? 1 : 0

  name             = var.archive_config.name
  description      = var.archive_config.description
  event_source_arn = aws_cloudwatch_event_bus.this.arn
  retention_days   = var.archive_config.retention_days
  event_pattern    = var.archive_config.event_pattern
}
