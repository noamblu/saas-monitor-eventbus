variable "name" {
  description = "Name of the schedule"
  type        = string
}

variable "schedule_expression" {
  description = "The schedule expression (e.g., rate(5 minutes) or cron(0 12 * * ? *))"
  type        = string
}

variable "target_arn" {
  description = "ARN of the target resource"
  type        = string
}

variable "group_name" {
  description = "Name of the schedule group"
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
