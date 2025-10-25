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


# Frontend Configuration
variable "frontend_container_port" {
  description = "Port exposed by the Streamlit container"
  type        = number
  default     = 8501
}

variable "frontend_desired_count" {
  description = "Number of Fargate tasks for frontend"
  type        = number
  default     = 1
}

variable "frontend_cpu" {
  description = "Fargate CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Fargate memory in MiB"
  type        = number
  default     = 512
}

variable "frontend_api_base_url" {
  description = "Backend API Gateway endpoint consumed by the frontend"
  type        = string
  default     = "https://api.resumeanalyzer.com"
}
