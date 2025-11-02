# © 2025 Abhishek M. All rights reserved.

import json
import time

import boto3
from botocore.exceptions import ClientError

from resume_analyzer.commons.models import FileMetadata, FileType
from resume_analyzer.commons.utils import generate_unique_identity, sanitize_file_names
from resume_analyzer.lambdas.file_handler import (
    PROCESSING_QUEUE_URL,
    S3_BUCKET,
    URL_EXPIRY_SECONDS,
    logger,
    sqs_service,
)


s3 = boto3.client("s3")


def generate_presigned_url(processing_job_id: str, file_meta: FileMetadata) -> str:
    """
    Generate a pre-signed URL for uploading a file to S3.
    Enforces SSE-KMS encryption.
    """
    try:
        url = s3.generate_presigned_url(
            ClientMethod="put_object",
            Params={
                "Bucket": S3_BUCKET,
                "Key": file_meta.s3_key,
                "ContentType": "application/pdf",
            },
            ExpiresIn=URL_EXPIRY_SECONDS,
        )
        logger.info(
            f"Generated presigned URL for {file_meta.file_name}",
            extra={"processing_job_id": processing_job_id, "s3_key": file_meta.s3_key},
        )
    except ClientError as e:
        logger.error(f"Error generating presigned URL: {e}")
        raise
    else:
        return url


def lambda_handler(event, context):
    """
    Lambda handler for API Gateway event.
    Generates a new processing_job_id,
    sanitizes filenames, and returns presigned URLs + JobMetadata.
    """
    try:
        # Create unique processing job ID
        processing_job_id = generate_unique_identity(prefix="proc")

        # Extract user-provided file names
        body = json.loads(event.get("body") or "{}")
        file_names = body.get("file_names", {})

        resume_name = sanitize_file_names(file_names.get("resume", "resume.pdf"))
        jd_name = sanitize_file_names(file_names.get("jd", "jd.pdf"))

        # Build file metadata
        files = [
            FileMetadata(
                file_name=resume_name,
                s3_key=f"input/{processing_job_id}/{resume_name}",
                file_type=FileType.RESUME,
            ),
            FileMetadata(
                file_name=jd_name,
                s3_key=f"input/{processing_job_id}/{jd_name}",
                file_type=FileType.JD,
            ),
        ]

        # Generate pre-signed URLs
        presigned_urls = {}
        for f in files:
            file_meta = FileMetadata(**f)
            presigned_urls[f["file_name"]] = generate_presigned_url(processing_job_id, file_meta)

        file_info_payload = {
            "job_id": processing_job_id,
            "bucket": S3_BUCKET,
            "files": files,
            "created_at": int(time.time() * 1000),
        }

        message_id = sqs_service.send_message(json.dumps(file_info_payload))

        logger.info(
            "File metadata sent to downstream SQS",
            extra={
                "processing_job_id": processing_job_id,
                "queue_url": PROCESSING_QUEUE_URL,
                "message_id": message_id,
            },
        )

        response_body = {
            "processing_job_id": processing_job_id,
            "upload_urls": presigned_urls,
            "job_metadata": file_info_payload,
        }

        logger.info(
            "Generated presigned URLs and job metadata",
        )

        return {
            "statusCode": 200,
            "body": json.dumps(response_body),
        }

    except Exception as e:
        logger.exception("Unhandled exception in file_handler lambda")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)}),
        }
