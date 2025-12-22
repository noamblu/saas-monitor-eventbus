variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS Profile to use for authentication"
  type        = string
  default     = "sandbox"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "SaaS-Monitor"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

variable "omnibus_url" {
  description = "URL of the Omnibus endpoint"
  type        = string
  default     = "https://example.com/omnibus"
}

variable "cert_path" {
  description = "Path to the certificate within the Lambda Layer"
  type        = string
  default     = "/opt/cert.pem"
}
