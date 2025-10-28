# ECR repository for the Lambda image
resource "aws_ecr_repository" "file_handler" {
  name                 = "${var.project_slug}/file-handler"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ai_resume_analyzer_key.arn
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_slug}-file-handler-ecr"
  })
}

