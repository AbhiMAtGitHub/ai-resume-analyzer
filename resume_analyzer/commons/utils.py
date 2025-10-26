# © 2025 Abhishek M. All rights reserved.

import re
import time
import uuid


def generate_unique_identity(prefix: str) -> str:
    """Generate a unique processing job ID."""
    return f"{prefix}{int(time.time())}_{uuid.uuid4().hex[:8]}"


def sanitize_file_names(name: str) -> str:
    """
    Sanitize user-uploaded filenames for safe S3 usage.
    - Converts to lowercase
    - Replaces spaces with underscores
    - Removes unsafe characters
    - Ensures `.pdf` extension
    """
    name = name.strip().lower()
    name = name.replace(" ", "_")
    name = re.sub(r"[^a-z0-9._-]", "_", name)
    if not name.endswith(".pdf"):
        name += ".pdf"
    return name
