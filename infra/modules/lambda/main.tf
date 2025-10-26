# Generic Lambda Module — reusable for all Resume Analyzer Lambdas

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = var.role_arn
  timeout       = var.timeout
  memory_size   = var.memory_size
  package_type  = var.package_type
  runtime       = var.runtime

  # For container image-based Lambda
  image_uri = var.image_uri

  # For zip-based Lambda (optional)
  filename         = var.filename
  handler          = var.handler
  source_code_hash = var.source_code_hash

  environment {
    variables = var.environment_variables
  }

  tags = merge(
    var.tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
    }
  )
}

# Optional CloudWatch Log Group (for better control and encryption)
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  count             = var.create_log_group ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = {
    "Name"        = "${var.function_name}-log-group"
    "Environment" = var.environment
  }
}
