# IAM role & policies for File Handler Lambda
data "aws_iam_policy_document" "file_handler_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "file_handler" {
  name               = "${var.project_slug}-file-handler-role"
  assume_role_policy = data.aws_iam_policy_document.file_handler_assume_role.json
  tags               = var.default_tags
}

# CloudWatch Logs
resource "aws_iam_role_policy_attachment" "file_handler_logs" {
  role       = aws_iam_role.file_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 & SQS & KMS access (least-priv)
data "aws_iam_policy_document" "file_handler_inline" {
  statement {
    sid     = "S3PutGetListForUploads"
    effect  = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.resume_analyzer_bucket.arn,
      "${aws_s3_bucket.resume_analyzer_bucket.arn}/*"
    ]
  }

  statement {
    sid     = "SendToProcessingQueue"
    effect  = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [
      aws_sqs_queue.resume_analyzer_processing_queue.arn
    ]
  }

  # If your bucket or SQS is KMS-encrypted with your CMK
  statement {
    sid     = "KmsUse"
    effect  = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [
      aws_kms_key.ai_resume_analyzer_key.arn
    ]
  }

    statement {
    sid    = "ECRPullAccess"
    effect = "Allow"
    actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
    ]
    resources = ["*"]
    }
}

resource "aws_iam_policy" "file_handler_inline" {
  name   = "${var.project_slug}-file-handler-inline"
  policy = data.aws_iam_policy_document.file_handler_inline.json
}

resource "aws_iam_role_policy_attachment" "file_handler_inline_attach" {
  role       = aws_iam_role.file_handler.name
  policy_arn = aws_iam_policy.file_handler_inline.arn
}


###################### Lambda role: start_pdf_text_extraction ######################

data "aws_iam_policy_document" "start_pdf_text_extraction_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "start_pdf_text_extraction" {
  name               = "${var.project_slug}-start-pdf-text-extraction-role"
  assume_role_policy = data.aws_iam_policy_document.start_pdf_text_extraction_assume_role.json
  tags               = var.default_tags
}

# Inline policy for the Lambda
data "aws_iam_policy_document" "start_pdf_text_extraction_inline" {
  # Logs
  statement {
    sid     = "Logs"
    effect  = "Allow"
    actions = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
  }

  # Read input objects from S3 (resume & jd)
  statement {
    sid     = "S3Read"
    effect  = "Allow"
    actions = ["s3:GetObject","s3:GetBucketLocation","s3:ListBucket"]
    resources = [
      aws_s3_bucket.resume_analyzer_bucket.arn,
      "${aws_s3_bucket.resume_analyzer_bucket.arn}/*"
    ]
  }

  # Consume processing queue (trigger source)
  statement {
    sid     = "SQSConsumeProcessing"
    effect  = "Allow"
    actions = ["sqs:ReceiveMessage","sqs:DeleteMessage","sqs:GetQueueAttributes","sqs:ChangeMessageVisibility"]
    resources = [aws_sqs_queue.resume_analyzer_processing_queue.arn]
  }

  # Publish downstream job-ids
  statement {
    sid     = "SQSPublishJobs"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.textract_jobs_queue.arn]
  }

  # Start Textract async jobs
  statement {
    sid     = "TextractStart"
    effect  = "Allow"
    actions = [
      "textract:StartDocumentTextDetection",
      "textract:StartDocumentAnalysis"
    ]
    resources = ["*"]
  }

  # Allow passing the role that Textract will assume to publish to SNS
  statement {
    sid     = "PassTextractServiceRole"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [aws_iam_role.textract_service_role.arn]
  }

  # KMS for encrypted resources (S3/SQS/SNS/ECR)
  statement {
    sid     = "KMS"
    effect  = "Allow"
    actions = ["kms:Decrypt","kms:Encrypt","kms:GenerateDataKey","kms:DescribeKey"]
    resources = [aws_kms_key.ai_resume_analyzer_key.arn]
  }
}

resource "aws_iam_policy" "start_pdf_text_extraction_inline" {
  name   = "${var.project_slug}-start-pdf-text-extraction-inline"
  policy = data.aws_iam_policy_document.start_pdf_text_extraction_inline.json
}

resource "aws_iam_role_policy_attachment" "start_pdf_text_extraction_inline_attach" {
  role       = aws_iam_role.start_pdf_text_extraction.name
  policy_arn = aws_iam_policy.start_pdf_text_extraction_inline.arn
}

# Role Textract assumes to publish to SNS
data "aws_iam_policy_document" "textract_service_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["textract.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "textract_service_role" {
  name               = "${var.project_slug}-textract-service-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.textract_service_assume.json
  tags               = var.default_tags
}

data "aws_iam_policy_document" "textract_publish_to_sns" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.textract_notifications.arn]
  }
}

resource "aws_iam_policy" "textract_publish_to_sns" {
  name   = "${var.project_slug}-textract-publish-sns-${var.environment}"
  policy = data.aws_iam_policy_document.textract_publish_to_sns.json
}

resource "aws_iam_role_policy_attachment" "textract_publish_attach" {
  role       = aws_iam_role.textract_service_role.name
  policy_arn = aws_iam_policy.textract_publish_to_sns.arn
}
