resource "aws_s3_bucket" "resume_analyzer_bucket" {
  bucket        = "ai-resume-analyzer-bucket"
  force_destroy = var.bucket_force_destroy

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [bucket]
  }

  tags = var.bucket_tags
}

# Enable versioning
resource "aws_s3_bucket_versioning" "resume_analyzer_versioning" {
  bucket = aws_s3_bucket.resume_analyzer_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "resume_analyzer_encryption" {
  bucket = aws_s3_bucket.resume_analyzer_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.ai_resume_analyzer_key.arn
    }

    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "resume_analyzer_block" {
  bucket                  = aws_s3_bucket.resume_analyzer_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "s3_bucket_name" {
  value = aws_s3_bucket.resume_analyzer_bucket.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.resume_analyzer_bucket.arn
}
