# SNS topic for Textract job notifications
resource "aws_sns_topic" "textract_notifications" {
  name              = "${var.project_slug}-textract-notifications-${var.environment}"
  kms_master_key_id = aws_kms_key.ai_resume_analyzer_key.arn
  tags              = var.default_tags
}

# Topic policy allowing the textract_service_role to publish
data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid     = "AllowTextractRolePublish"
    effect  = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.textract_service_role.arn]
    }

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.textract_notifications.arn]
  }
}


resource "aws_sns_topic_policy" "textract_topic_policy" {
  arn    = aws_sns_topic.textract_notifications.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}
