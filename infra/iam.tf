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
}

resource "aws_iam_policy" "file_handler_inline" {
  name   = "${var.project_slug}-file-handler-inline"
  policy = data.aws_iam_policy_document.file_handler_inline.json
}

resource "aws_iam_role_policy_attachment" "file_handler_inline_attach" {
  role       = aws_iam_role.file_handler.name
  policy_arn = aws_iam_policy.file_handler_inline.arn
}
