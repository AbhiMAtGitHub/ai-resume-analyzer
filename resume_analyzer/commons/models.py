# © 2025 Abhishek M. All rights reserved.

from __future__ import annotations

import time
from enum import StrEnum

from pydantic import BaseModel, Field


class FileType(StrEnum):
    """Enumeration for supported file types."""

    RESUME = "resume"
    JD = "jd"


class LogLevel(StrEnum):
    """
    Enum for standardized logging levels across the project.

    Attributes:
        INFO: General informational messages.
        DEBUG: Detailed debugging information.
        WARNING: Indications of potential issues that aren't errors yet.
        ERROR: Errors that caused an operation to fail.
        CRITICAL: Serious errors that may require immediate attention.
    """

    INFO = "INFO"
    DEBUG = "DEBUG"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


class FileMetadata(BaseModel):
    """
    Represents metadata for each uploaded file.

    Attributes:
        file_name: Original name of the uploaded file (e.g., resume.pdf).
        s3_key: Full S3 object key where the file is stored.
        file_type: Type of the uploaded file, see FileType enum.
    """

    file_name: str = Field(..., description="Original file name, e.g., resume.pdf")
    s3_key: str = Field(..., description="Full S3 object key for the uploaded file")
    file_type: str = Field(..., description="Type of the file, e.g., 'resume' or 'jd'")


class JobMetadata(BaseModel):
    """
    Represents a processing job and its state across Lambdas/SQS.

    Attributes:
        job_id: Unique ID for the overall processing job.
        bucket: S3 bucket name where related files are stored.
        files: List of FileMetadata for all uploaded files.
        created_at: Epoch timestamp (ms) when the job was created.
        status: Current job status (e.g., UPLOADED, PROCESSING, COMPLETED).
        textract_job_ids: Mapping of file type → Textract Job ID.
        output_s3_key: S3 key of final analysis output JSON.
        error: Error message if job failed.
    """

    job_id: str = Field(..., description="Unique job ID for tracking")
    bucket: str = Field(..., description="S3 bucket where input files reside")
    files: list[FileMetadata] = Field(..., description="List of uploaded file metadata")
    created_at: int = Field(
        default_factory=lambda: int(time.time() * 1000),
        description="Epoch timestamp (ms) when job created",
    )
    status: str = Field(default="NULL", description="Current job status")
    textract_job_ids: dict[str, str] | None = Field(
        default_factory=dict, description="Map of file type to Textract Job IDs"
    )
    output_s3_key: str | None = Field(
        default=None, description="S3 key of generated analysis result JSON"
    )
    error: str | None = Field(default=None, description="Error message if processing failed")

    def to_sqs_message(self) -> str:
        """Serialize the job metadata to JSON string for SQS messaging."""
        return self.model_dump_json()

    def to_dict(self) -> dict:
        """Return the job metadata as a plain Python dictionary."""
        return self.model_dump()
