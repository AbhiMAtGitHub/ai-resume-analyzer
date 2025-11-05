# © 2025 Abhishek M. All rights reserved.

import boto3
from aws_lambda_powertools import Logger
from botocore.exceptions import ClientError


logger = Logger(service="textract_utils")

textract_client = boto3.client("textract")


class TextractService:
    """
    Reusable service class for Textract operations:
    - Start async document text or analysis jobs
    - Get job status
    - Retrieve results pages
    """

    def __init__(self, sns_topic_arn: str, service_role_arn: str):
        self.sns_topic_arn = sns_topic_arn
        self.service_role_arn = service_role_arn

    def start_text_detection(self, bucket: str, key: str, job_id: str, file_type: str) -> str:
        """
        Start an asynchronous text detection job (PDF or image).
        Uses a consistent idempotent token based on job_id and file_type.
        """
        try:
            document_location = {"S3Object": {"Bucket": bucket, "Name": key}}
            token = f"{job_id}:{file_type}"

            response = textract_client.start_document_text_detection(
                DocumentLocation=document_location,
                ClientRequestToken=token,
                JobTag=token,
                NotificationChannel={
                    "SNSTopicArn": self.sns_topic_arn,
                    "RoleArn": self.service_role_arn,
                },
            )

            job_id_returned = response["JobId"]
            logger.info(
                f"Started Textract text detection job for {file_type}",
                extra={
                    "job_id": job_id,
                    "textract_job_id": job_id_returned,
                    "s3_key": key,
                },
            )
            return job_id_returned

        except ClientError as e:
            logger.error(f"Failed to start text detection for {file_type}: {e}", exc_info=True)
            raise

    def start_document_analysis(
        self, bucket: str, key: str, job_id: str, feature_types: list[str]
    ) -> str:
        """
        Start an asynchronous document analysis job (for forms/tables).
        """
        try:
            token = f"{job_id}:analysis"
            response = textract_client.start_document_analysis(
                DocumentLocation={"S3Object": {"Bucket": bucket, "Name": key}},
                ClientRequestToken=token,
                JobTag=token,
                FeatureTypes=feature_types,
                NotificationChannel={
                    "SNSTopicArn": self.sns_topic_arn,
                    "RoleArn": self.service_role_arn,
                },
            )
            job_id_returned = response["JobId"]
            logger.info(
                "Started Textract document analysis",
                extra={
                    "job_id": job_id,
                    "textract_job_id": job_id_returned,
                    "features": feature_types,
                },
            )
            return job_id_returned
        except ClientError as e:
            logger.error(f"Error starting Textract analysis job: {e}", exc_info=True)
            raise

    def get_job_status(self, textract_job_id: str, analysis: bool = False) -> str:
        """
        Retrieve the job status (IN_PROGRESS, SUCCEEDED, FAILED).
        """
        try:
            fn = (
                textract_client.get_document_analysis
                if analysis
                else textract_client.get_document_text_detection
            )
            resp = fn(JobId=textract_job_id, MaxResults=1)
            status = resp["JobStatus"]
            logger.debug(f"Textract job {textract_job_id} status: {status}")
            return status
        except ClientError as e:
            logger.error(f"Failed to fetch Textract job status: {e}", exc_info=True)
            raise

    def get_job_result(self, textract_job_id: str, analysis: bool = False) -> list[dict]:
        """
        Fetch all result pages for a completed Textract job.
        """
        try:
            fn = (
                textract_client.get_document_analysis
                if analysis
                else textract_client.get_document_text_detection
            )
            pages, next_token = [], None

            while True:
                kwargs = {"JobId": textract_job_id}
                if next_token:
                    kwargs["NextToken"] = next_token

                resp = fn(**kwargs)
                pages.extend(resp.get("Blocks", []))
                next_token = resp.get("NextToken")

                if not next_token:
                    break

            logger.info(
                f"Fetched {len(pages)} blocks from Textract job {textract_job_id}",
                extra={"job_id": textract_job_id},
            )
            return pages

        except ClientError as e:
            logger.error(f"Error retrieving Textract job results: {e}", exc_info=True)
            raise
