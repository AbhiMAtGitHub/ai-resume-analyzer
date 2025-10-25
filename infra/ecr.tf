# ECR Repository (shared)
resource "aws_ecr_repository" "frontend_repo" {
  name                 = "${var.project_name}-${var.environment}-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ecr_lifecycle_policy" "frontend_repo_policy" {
  repository = aws_ecr_repository.frontend_repo.name
  policy     = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Keep last 5 images",
      selection    = {
        tagStatus     = "any",
        countType     = "imageCountMoreThan",
        countNumber   = 5
      },
      action = { type = "expire" }
    }]
  })
}

output "frontend_ecr_repo_url" {
  description = "ECR repository URL for frontend container"
  value       = aws_ecr_repository.frontend_repo.repository_url
}
