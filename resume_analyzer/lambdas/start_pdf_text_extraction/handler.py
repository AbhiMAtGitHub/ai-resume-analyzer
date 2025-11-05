# © 2025 Abhishek M. All rights reserved.

import json

from aws_lambda_powertools.utilities.data_classes import SQSEvent, event_source

from resume_analyzer.commons.textract import TextractService
from resume_analyzer.lambdas.start_pdf_text_extraction import (
    S3_BUCKET,
    TEXTRACT_SERVICE_ROLE_ARN,
    TEXTRACT_SNS_TOPIC_ARN,
    logger,
    sqs_service,
)


@event_source(data_class=SQSEvent)
def lambda_handler(event: SQSEvent, context):
    """
    Triggered by SQS. Each record represents a processing job with uploaded resume and JD.
    For each record, starts Textract jobs and sends { job_id, textract_job_ids } downstream.
    """
    textract_service = TextractService(
        sns_topic_arn=TEXTRACT_SNS_TOPIC_ARN,
        service_role_arn=TEXTRACT_SERVICE_ROLE_ARN,
    )

    batch_item_failures = []

    for record in event.records:  # record: SQSRecord
        try:
            body = json.loads(record.body)
            job_id = body["job_id"]
            bucket = body.get("bucket", S3_BUCKET)
            files = body["files"]

            textract_jobs = {}
            for f in files:
                s3_key = f["s3_key"]
                file_type = f["file_type"]

                textract_job_id = textract_service.start_text_detection(
                    bucket=bucket,
                    key=s3_key,
                    job_id=job_id,
                    file_type=file_type,
                )
                textract_jobs[file_type] = textract_job_id

            payload = {
                "job_id": job_id,
                "bucket": bucket,
                "textract_job_ids": textract_jobs,
            }

            sqs_service.send_message(json.dumps(payload))
            logger.info(
                "Started Textract jobs and dispatched metadata",
                extra={"job_id": job_id, "payload": payload},
            )

        except Exception as e:
            logger.exception("Failed processing record", extra={"record_id": record.message_id})
            batch_item_failures.append({"itemIdentifier": record.message_id})

    return {"batchItemFailures": batch_item_failures}
