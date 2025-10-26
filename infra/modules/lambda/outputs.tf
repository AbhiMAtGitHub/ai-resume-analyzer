# © 2025 Abhishek M. All rights reserved.

output "lambda_arn" {
  description = "ARN of the created Lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_name" {
  description = "Name of the created Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}
