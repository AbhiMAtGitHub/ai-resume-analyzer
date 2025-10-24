# Create a KMS Key for S3 encryption
resource "aws_kms_key" "ai-resume_analyzer_key" {
  description             = "KMS key for Resume Analyzer S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "Enable IAM User Permissions",
        Effect   = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "resume-analyzer-kms-key"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# Alias for readability
resource "aws_kms_alias" "resume_analyzer_alias" {
  name          = "alias/${var.project_name}-${var.bucket_tags["Environment"]}-key"
  target_key_id = aws_kms_key.ai-resume_analyzer_key.id
}


output "kms_key_arn" {
  value = aws_kms_key.ai-resume_analyzer_key.arn
}
