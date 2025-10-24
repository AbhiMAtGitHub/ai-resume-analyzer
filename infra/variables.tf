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

variable "bucket_name" {
  description = "S3 bucket name for Resume Analyzer project"
  type        = string
  default     = "ai-resume-analyzer-bucket"
}

variable "bucket_force_destroy" {
  description = "Force destroy the bucket on terraform destroy"
  type        = bool
  default     = true
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
