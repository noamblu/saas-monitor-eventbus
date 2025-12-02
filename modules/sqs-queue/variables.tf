variable "name" {
  description = "The name of the SQS queue"
  type        = string
}

variable "dlq_config" {
  description = "Configuration for the Dead Letter Queue"
  type = object({
    enabled           = optional(bool, false)
    name              = optional(string, null)
    max_receive_count = optional(number, 5)
  })
  default = {}
  validation {
    condition     = var.dlq_config.enabled == false || var.dlq_config.name != null
    error_message = "DLQ name must be provided if DLQ is enabled."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "fifo_queue" {
  description = "Boolean designating a FIFO queue"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO queues"
  type        = bool
  default     = false
}
