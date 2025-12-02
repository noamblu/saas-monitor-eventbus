variable "name" {
  description = "The name of the EventBridge bus"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "archive_config" {
  description = "Configuration for EventBridge Archive"
  type = object({
    enabled        = optional(bool, false)
    name           = optional(string, null)
    description    = optional(string, null)
    retention_days = optional(number, 0) # 0 means infinite
    event_pattern  = optional(string, null)
  })
  default = {}
}
