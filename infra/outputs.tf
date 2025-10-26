output "file_handler_lambda_name" {
  value = module.file_handler_lambda.lambda_name
}

output "processing_queue_url" {
  value = aws_sqs_queue.resume_analyzer_processing_queue.id
}
