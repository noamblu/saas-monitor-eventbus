variable "name" {
  description = "Name of the schedule"
  type        = string
}

variable "schedule_expression" {
  description = "Schedule expression (e.g., rate(5 minutes))"
  type        = string
}

variable "target_config" {
  description = "Configuration for the target"
  type = object({
    arn      = string
    role_arn = string
    input    = optional(string, "{}")
  })
}

variable "flexible_time_window" {
  description = "Configuration for flexible time window"
  type = object({
    mode                      = string # "OFF" or "FLEXIBLE"
    maximum_window_in_minutes = optional(number)
  })
  default = {
    mode = "OFF"
  }
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default     = {}
}
