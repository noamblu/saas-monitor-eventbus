resource "aws_cloudwatch_event_rule" "this" {
  name           = var.name
  description    = var.description
  event_bus_name = var.bus_name
  event_pattern  = var.event_pattern
  tags           = var.tags
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = var.targets

  rule           = aws_cloudwatch_event_rule.this.name
  event_bus_name = var.bus_name
  target_id      = each.key
  arn            = each.value.arn
  role_arn       = each.value.role_arn

  dynamic "sqs_target" {
    for_each = each.value.message_group_id != null ? [1] : []
    content {
      message_group_id = each.value.message_group_id
    }
  }

  # Dynamic input transformer block could be added here if needed, 
  # but keeping it simple for now as per requirements.
}
