output "processing_queue_url" {
  value = aws_sqs_queue.resume_analyzer_processing_queue.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.file_handler.repository_url
}

output "file_handler_lambda_name" {
  value = aws_lambda_function.file_handler.function_name
}

output "file_handler_lambda_arn" {
  value = aws_lambda_function.file_handler.arn
}

output "api_invoke_url" {
  value = "https://${aws_api_gateway_rest_api.resume_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.dev.stage_name}"
}

output "api_presigned_urls_endpoint" {
  value = "${output.api_invoke_url.value}/presigned-urls"
  description = "POST this from Streamlit to get two presigned URLs"
}
