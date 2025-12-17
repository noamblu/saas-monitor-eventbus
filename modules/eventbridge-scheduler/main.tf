resource "aws_scheduler_schedule" "this" {
  name       = var.name
  group_name = "default"

  flexible_time_window {
    mode                      = var.flexible_time_window.mode
    maximum_window_in_minutes = var.flexible_time_window.maximum_window_in_minutes
  }

  schedule_expression = var.schedule_expression

  target {
    arn      = var.target_config.arn
    role_arn = var.target_config.role_arn
    input    = var.target_config.input
  }
}
