# IAM Role for Lambda
resource "aws_iam_role" "file_handler_role" {
  name = "resume-analyzer-dev-file-handler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "file_handler_policy" {
  name = "resume-analyzer-dev-file-handler-policy"
  role = aws_iam_role.file_handler_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.resume_analyzer_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.resume_analyzer_bucket.id}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage"
        ],
        Resource = aws_sqs_queue.resume_analyzer_processing_queue.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Allow Lambda to pull container images from ECR
resource "aws_iam_role_policy" "file_handler_ecr_pull" {
  name = "resume-analyzer-dev-file-handler-ecr-pull"
  role = aws_iam_role.file_handler_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        Resource = "*"
      }
    ]
  })
}

# Lambda Function
module "file_handler_lambda" {
  source        = "./modules/lambda"
  function_name = "resume-analyzer-dev-file-handler-lambda"
  description   = "Generates presigned URLs and sends JobMetadata to downstream SQS"
  role_arn      = aws_iam_role.file_handler_role.arn
  image_uri     = var.file_handler_image_uri

  environment_variables = {
    S3_BUCKET              = aws_s3_bucket.resume_analyzer_bucket.bucket
    URL_EXPIRY_SECONDS     = "900"
    DOWNSTREAM_QUEUE_URL   = aws_sqs_queue.resume_analyzer_processing_queue.id
    POWERTOOLS_SERVICE_NAME = "file_handler"
    POWERTOOLS_LOG_LEVEL    = "INFO"
  }

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = aws_kms_key.ai_resume_analyzer_key.arn
}


# Optional: CloudWatch Log Group
resource "aws_cloudwatch_log_group" "file_handler_logs" {
  name              = "/aws/lambda/${module.file_handler_lambda.lambda_name}"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.ai_resume_analyzer_key.arn
}
