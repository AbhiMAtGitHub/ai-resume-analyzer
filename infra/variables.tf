variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
  default     = "resume-analyzer"
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "S3 bucket name for Resume Analyzer project"
  type        = string
  default     = "ai-resume-analyzer-bucket"
}

variable "bucket_force_destroy" {
  description = "Force destroy the bucket on terraform destroy"
  type        = bool
  default     = false
}

variable "bucket_tags" {
  description = "Tags for the S3 bucket"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "resume-analyzer"
    ManagedBy   = "Terraform"
  }
}


variable "project_slug" {
  description = "Short slug used to name resources"
  type        = string
  default     = "resume-analyzer"
}

variable "file_handler_image_tag" {
  description = "Docker image tag to deploy for the file-handler Lambda"
  type        = string
  default     = "latest"
}

variable "presign_url_expiry_seconds" {
  description = "Expiry (in seconds) for S3 presigned PUT URLs"
  type        = number
  default     = 900 # 15 minutes
}

variable "log_retention_days" {
  description = "CloudWatch log retention for Lambda"
  type        = number
  default     = 14
}

variable "apigw_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}

# Default tagging convention for all resources
variable "default_tags" {
  description = "Default resource tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "resume-analyzer"
    ManagedBy   = "Terraform"
  }
}

