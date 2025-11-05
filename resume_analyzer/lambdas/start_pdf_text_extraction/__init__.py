# © 2025 Abhishek M. All rights reserved.
import os

from aws_lambda_powertools import Logger

from resume_analyzer.commons.sqs import SQSService


logger = Logger(service="start_pdf_text_extraction", level=os.getenv("LOG_LEVEL", "INFO"))

S3_BUCKET = os.environ["BUCKET_NAME"]
PROCESSING_QUEUE_URL = os.environ["PROCESSING_QUEUE_URL"]

TEXTRACT_SNS_TOPIC_ARN = os.environ["TEXTRACT_SNS_TOPIC_ARN"]
TEXTRACT_SERVICE_ROLE_ARN = os.environ["TEXTRACT_SERVICE_ROLE_ARN"]
TEXTRACT_JOBS_QUEUE_URL = os.environ["TEXTRACT_JOBS_QUEUE_URL"]

sqs_service = SQSService(queue_url=TEXTRACT_JOBS_QUEUE_URL)
