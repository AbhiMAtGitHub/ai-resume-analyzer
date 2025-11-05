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




# Downstream queue to carry { job_id, textract_job_ids }
resource "aws_sqs_queue" "textract_jobs_queue" {
  name                       = "${var.project_slug}-textract-jobs-${var.environment}"
  kms_master_key_id          = aws_kms_key.ai_resume_analyzer_key.arn
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400
  tags                       = var.default_tags
}

# SQS subscribed to the SNS topic for job completion notifications
resource "aws_sqs_queue" "textract_notifications_queue" {
  name              = "${var.project_slug}-textract-notifications-${var.environment}"
  kms_master_key_id = aws_kms_key.ai_resume_analyzer_key.arn
  tags              = var.default_tags
}

data "aws_iam_policy_document" "textract_notifications_queue_policy" {
  statement {
    sid        = "AllowSNSTopic"
    effect     = "Allow"
    actions    = ["SQS:SendMessage"]
    principals { type = "Service", identifiers = ["sns.amazonaws.com"] }
    resources  = [aws_sqs_queue.textract_notifications_queue.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.textract_notifications.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "textract_notifications_queue_policy" {
  queue_url = aws_sqs_queue.textract_notifications_queue.id
  policy    = data.aws_iam_policy_document.textract_notifications_queue_policy.json
}

resource "aws_sns_topic_subscription" "textract_notifications_sub" {
  topic_arn = aws_sns_topic.textract_notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.textract_notifications_queue.arn
}
