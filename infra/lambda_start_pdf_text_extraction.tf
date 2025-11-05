################ Lambda: start_pdf_text_extraction ################

# Log group for the Lambda
resource "aws_cloudwatch_log_group" "start_pdf_text_extraction" {
  name              = "/aws/lambda/${var.project_slug}-start-pdf-text-extraction"
  retention_in_days = var.log_retention_days
  tags              = var.default_tags
}

# Construct the ECR image URI
locals {
  start_pdf_text_extraction_image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.start_pdf_text_extraction.name}:${var.start_pdf_text_extraction_image_tag}"
}

resource "aws_lambda_function" "start_pdf_text_extraction" {
  function_name = "${var.project_slug}-start-pdf-text-extraction"
  role          = aws_iam_role.start_pdf_text_extraction.arn
  package_type  = "Image"
  image_uri     = local.start_pdf_text_extraction_image_uri
  timeout       = 120
  memory_size   = 512
  architectures = ["x86_64"] # align with your existing images

  environment {
    variables = {
      BUCKET_NAME              = aws_s3_bucket.resume_analyzer_bucket.bucket
      PROCESSING_QUEUE_URL     = aws_sqs_queue.resume_analyzer_processing_queue.url
      TEXTRACT_SNS_TOPIC_ARN   = aws_sns_topic.textract_notifications.arn
      TEXTRACT_SERVICE_ROLE_ARN= aws_iam_role.textract_service_role.arn
      TEXTRACT_JOBS_QUEUE_URL  = aws_sqs_queue.textract_jobs_queue.url
      LOG_LEVEL                = "INFO"
      USE_ANALYSIS             = tostring(var.use_analysis)
      FEATURE_TYPES            = var.feature_types
    }
  }

  tags = var.default_tags
}

# SQS trigger mapping (source: processing queue)
resource "aws_lambda_event_source_mapping" "processing_to_start_pdf_text_extraction" {
  event_source_arn                    = aws_sqs_queue.resume_analyzer_processing_queue.arn
  function_name                       = aws_lambda_function.start_pdf_text_extraction.arn
  batch_size                          = 5
  maximum_batching_window_in_seconds  = 5
  function_response_types             = ["ReportBatchItemFailures"] # partial batch failure support
  scaling_config {
    maximum_concurrency = 5
  }
}
