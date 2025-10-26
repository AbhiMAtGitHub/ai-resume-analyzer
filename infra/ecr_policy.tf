data "aws_ecr_repository" "file_handler_repo" {
  name = "resume-analyzer-file-handler"
}

resource "aws_ecr_repository_policy" "file_handler_repo_policy" {
  repository = data.aws_ecr_repository.file_handler_repo.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowLambdaToPullImages",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid = "AllowAccountAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
      }
    ]
  })
}