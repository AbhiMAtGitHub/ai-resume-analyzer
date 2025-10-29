# © 2025 Abhishek M. All rights reserved.
import os

from aws_lambda_powertools import Logger

from resume_analyzer.commons.sqs import SQSService


logger = Logger(service="file_handler")

S3_BUCKET = os.environ["BUCKET_NAME"]
PROCESSING_QUEUE_URL = os.environ["PROCESSING_QUEUE_URL"]
URL_EXPIRY_SECONDS = int(os.environ.get("URL_EXPIRY_SECONDS", 900))  # 15 min

sqs_service = SQSService(PROCESSING_QUEUE_URL)
