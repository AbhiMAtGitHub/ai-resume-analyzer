# © 2025 Abhishek M. All rights reserved.

from typing import Any

import boto3
from aws_lambda_powertools import Logger
from botocore.exceptions import ClientError

from resume_analyzer.commons.models import JobMetadata, LogLevel


logger = Logger()
logger.setLevel(LogLevel.INFO)

sqs_client = boto3.client("sqs")


class SQSService:
    """
    Reusable SQS utility for sending and receiving JobMetadata messages.

    Methods:
        send_message()     → Send a message to a specific SQS queue.
        send_job_metadata()→ Serialize and send JobMetadata.
        receive_messages() → Pull messages from a queue (for batch processing).
        delete_message()   → Delete a processed message from the queue.
    """

    def __init__(self, queue_url: str):
        """
        Initialize the SQSService with a queue URL.
        Args:
            queue_url: Full SQS queue URL (not ARN).
        """
        self.queue_url = queue_url

    def send_message(
        self,
        message_body: str,
        delay_seconds: int = 0,
        message_attributes: dict[str, Any] | None = None,
    ) -> str:
        """
        Send a raw JSON message to SQS.

        Args:
            message_body: The JSON string to send.
            delay_seconds: Optional delay (0 to 900s).
            message_attributes: Optional SQS message attributes.

        Returns:
            The SQS MessageId.
        """
        try:
            params = {
                "QueueUrl": self.queue_url,
                "MessageBody": message_body,
                "DelaySeconds": delay_seconds,
            }
            if message_attributes:
                params["MessageAttributes"] = message_attributes

            response = sqs_client.send_message(**params)
            message_id = response["MessageId"]

            logger.info(
                "Message sent to SQS",
                extra={"queue_url": self.queue_url, "message_id": message_id},
            )

        except ClientError as e:
            logger.error(f"Error sending message to SQS: {e}", exc_info=True)
            raise
        else:
            return message_id

    def send_job_metadata(self, job_metadata: JobMetadata, delay_seconds: int = 0) -> str:
        """
        Serialize and send a JobMetadata object to SQS.

        Args:
            job_meta: The JobMetadata object to send.
            delay_seconds: Optional delay before delivery.

        Returns:
            The SQS MessageId.
        """
        message_body = job_metadata.to_sqs_message()
        return self.send_message(message_body, delay_seconds)

    def receive_messages(self, max_messages: int = 5, wait_time: int = 5) -> list[dict[str, Any]]:
        """
        Receive a batch of messages from SQS.

        Args:
            max_messages: Maximum number of messages to fetch (default 5).
            wait_time: Long polling duration (seconds, max 20).

        Returns:
            A list of SQS message dicts.
        """
        try:
            response = sqs_client.receive_message(
                QueueUrl=self.queue_url,
                MaxNumberOfMessages=max_messages,
                WaitTimeSeconds=wait_time,
            )
            messages = response.get("Messages", [])
            logger.info(f"Fetched {len(messages)} messages from queue {self.queue_url}")

        except ClientError as e:
            logger.error(f"Error receiving messages from SQS: {e}", exc_info=True)
            raise
        else:
            return messages

    def delete_message(self, receipt_handle: str) -> None:
        """
        Delete a message from the queue after successful processing.

        Args:
            receipt_handle: The ReceiptHandle returned by receive_message.
        """
        try:
            sqs_client.delete_message(QueueUrl=self.queue_url, ReceiptHandle=receipt_handle)
            logger.info("Deleted message from SQS", extra={"queue_url": self.queue_url})
        except ClientError as e:
            logger.error(f"Error deleting message from SQS: {e}", exc_info=True)
            raise
