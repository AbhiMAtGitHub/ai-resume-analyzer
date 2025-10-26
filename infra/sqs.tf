resource "aws_sqs_queue" "resume_analyzer_processing_queue" {
  name                      = "resume-analyzer-dev-processing-queue"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400
  kms_master_key_id          = aws_kms_key.ai_resume_analyzer_key.arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# DLQ
resource "aws_sqs_queue" "resume_analyzer_processing_queue_dlq" {
  name = "resume-analyzer-dev-processing-dlq"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Attach DLQ to main queue
resource "aws_sqs_queue_redrive_policy" "resume_analyzer_redrive" {
  queue_url = aws_sqs_queue.resume_analyzer_processing_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.resume_analyzer_processing_queue_dlq.arn
    maxReceiveCount     = 5
  })
}
