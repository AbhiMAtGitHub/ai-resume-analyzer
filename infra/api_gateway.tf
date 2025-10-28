########################################
# API Gateway (REST) for File Handler
########################################

# REST API
resource "aws_api_gateway_rest_api" "resume_api" {
  name        = "${var.project_slug}-api"
  description = "REST API for Resume Analyzer - File Handler"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = var.default_tags
}

# Resource path: /presigned-urls
resource "aws_api_gateway_resource" "presigned_urls" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  parent_id   = aws_api_gateway_rest_api.resume_api.root_resource_id
  path_part   = "presigned-urls"
}

# Method: POST
resource "aws_api_gateway_method" "presigned_urls_post" {
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
  resource_id   = aws_api_gateway_resource.presigned_urls.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration: Lambda proxy
resource "aws_api_gateway_integration" "presigned_urls_post" {
  rest_api_id             = aws_api_gateway_rest_api.resume_api.id
  resource_id             = aws_api_gateway_resource.presigned_urls.id
  http_method             = aws_api_gateway_method.presigned_urls_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.file_handler.arn}/invocations"
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "apigw_invoke_file_handler" {
  statement_id  = "AllowAPIGatewayInvokeFileHandler"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.resume_api.id}/*/${aws_api_gateway_method.presigned_urls_post.http_method}${aws_api_gateway_resource.presigned_urls.path}"
}

# Deployment + Stage
resource "aws_api_gateway_deployment" "resume_api" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id

  triggers = {
    redeploy_hash = sha1(jsonencode({
      resources = [
        aws_api_gateway_resource.presigned_urls.id,
      ],
      methods = [
        aws_api_gateway_method.presigned_urls_post.id,
      ],
      integrations = [
        aws_api_gateway_integration.presigned_urls_post.id,
      ]
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
  deployment_id = aws_api_gateway_deployment.resume_api.id
  stage_name    = var.apigw_stage_name
  tags          = var.default_tags
}
