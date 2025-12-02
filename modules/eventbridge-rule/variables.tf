variable "name" {
  description = "The name of the rule"
  type        = string
}

variable "description" {
  description = "The description of the rule"
  type        = string
  default     = null
}

variable "bus_name" {
  description = "The name of the event bus to associate with this rule"
  type        = string
}

variable "event_pattern" {
  description = "The event pattern for the rule (JSON string)"
  type        = string
}

variable "targets" {
  description = "A map of targets to add to the rule"
  type = map(object({
    arn              = string
    role_arn         = optional(string)
    message_group_id = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
