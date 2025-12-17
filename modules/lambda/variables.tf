variable "name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "source_config" {
  description = "Configuration for source code (file or directory)"
  type = object({
    path = string
    type = string # "file" or "dir"
  })
  validation {
    condition     = contains(["file", "dir"], var.source_config.type)
    error_message = "source_config.type must be 'file' or 'dir'."
  }
}

variable "handler" {
  description = "Lambda handler"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9"
}

variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "create_url" {
  description = "Whether to create a Function URL"
  type        = bool
  default     = false
}

variable "additional_policies" {
  description = "List of IAM policy JSON strings to attach"
  type        = list(string)
  default     = []
}

variable "vpc_config" {
  description = "VPC configuration for the Lambda"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "tags" {
  description = "Tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Timeout in seconds"
  type        = number
  default     = 3
}

variable "layers" {
  description = "List of Lambda Layer ARNs (optional)"
  type        = list(string)
  default     = []
}
