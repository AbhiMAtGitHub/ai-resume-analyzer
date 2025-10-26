variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "role_arn" {
  description = "IAM Role ARN for the Lambda function"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (if not image-based)"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 20
}

variable "memory_size" {
  description = "Memory allocation in MB"
  type        = number
  default     = 256
}

variable "package_type" {
  description = "Deployment package type: Zip or Image"
  type        = string
  default     = "Image"
}

variable "image_uri" {
  description = "ECR image URI for container-based Lambda"
  type        = string
  default     = null
}

variable "filename" {
  description = "Path to zip file (for zip-based Lambdas)"
  type        = string
  default     = null
}

variable "handler" {
  description = "Handler path (for zip-based Lambdas)"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Base64 SHA256 hash of the deployment package"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Environment variables map for the Lambda"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
}

variable "tags" {
  description = "Extra tags for resources"
  type        = map(string)
  default     = {}
}

variable "create_log_group" {
  description = "Whether to create a CloudWatch log group"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period (days)"
  type        = number
  default     = 14
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting logs (optional)"
  type        = string
  default     = null
}
