output "file_handler_lambda_name" {
  value = module.file_handler_lambda.lambda_name
}

output "processing_queue_url" {
  value = aws_sqs_queue.resume_analyzer_processing_queue.id
}

output "ecr_repository_url" {
  description = "ECR repository URL for file handler image"
  value       = aws_ecr_repository.file_handler.repository_url
}

output "file_handler_lambda_name_new" {
  description = "Lambda function name"
  value       = aws_lambda_function.file_handler.function_name
}

output "file_handler_lambda_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.file_handler.arn
}

output "api_invoke_url" {
  description = "Base invoke URL for API Gateway"
  value       = "https://${aws_api_gateway_rest_api.resume_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}"
}

output "api_presigned_urls_endpoint" {
  description = "POST endpoint for generating presigned URLs (hit from Streamlit)"
  value       = "https://${aws_api_gateway_rest_api.resume_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}/presigned-urls"
}
