# File Handler Lambda (container image)

# Optional: a log group with retention
resource "aws_cloudwatch_log_group" "file_handler" {
  name              = "/aws/lambda/${var.project_slug}-file-handler"
  retention_in_days = var.log_retention_days
  tags              = var.default_tags
}

# Construct the ECR image URI from account/region/repo:tag
locals {
  file_handler_image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.file_handler.name}:${var.file_handler_image_tag}"
}

resource "aws_lambda_function" "file_handler" {
  function_name = "${var.project_slug}-file-handler"
  package_type  = "Image"
  image_uri     = local.file_handler_image_uri
  role          = aws_iam_role.file_handler.arn
  timeout       = 15
  memory_size   = 512
  architectures = ["x86_64"] # change to ["arm64"] if your image is arm64

  environment {
    variables = {
      BUCKET_NAME            = aws_s3_bucket.resume_analyzer_bucket.bucket
      PROCESSING_QUEUE_URL   = aws_sqs_queue.resume_analyzer_processing_queue.url
      URL_EXPIRY_SECONDS     = tostring(var.presign_url_expiry_seconds) # e.g., 900
      LOG_LEVEL              = "INFO"
    }
  }

  tags = var.default_tags
}
