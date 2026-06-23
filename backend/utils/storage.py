"""
Supabase Storage helper.

Provides server-side upload, signed URL generation, and deletion
for Supabase Storage buckets. Falls back to a no-op when Supabase
is not configured, so the app stays functional in dev without it.
"""
import os
import uuid
import logging
import requests
from django.conf import settings

logger = logging.getLogger(__name__)

ALLOWED_MIME_TYPES = {
    "image/jpeg", "image/png", "image/webp", "image/gif", "image/svg+xml",
    "application/pdf",
    "video/mp4", "video/quicktime",
}

MAX_FILE_SIZE = 25 * 1024 * 1024


def is_configured() -> bool:
    return bool(settings.SUPABASE_URL and settings.SUPABASE_SERVICE_KEY)


def _bucket() -> str:
    return getattr(settings, "SUPABASE_STORAGE_BUCKET", "boulotman") or "boulotman"


def _headers() -> dict:
    return {
        "apikey": settings.SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {settings.SUPABASE_SERVICE_KEY}",
    }


def generate_object_key(prefix: str, filename: str) -> str:
    ext = (filename.rsplit(".", 1)[-1] or "bin").lower()
    safe_prefix = prefix.strip("/").replace("..", "").replace("\\", "/")
    return f"{safe_prefix}/{uuid.uuid4()}.{ext}"


def upload_file(file_obj, prefix: str = "uploads", bucket: str | None = None) -> dict:
    """
    Upload a file-like object to Supabase Storage.

    Returns:
        {"key": str, "url": str, "public_url": str|None, "size": int, "content_type": str}
    """
    if not is_configured():
        logger.warning("Supabase not configured; skipping upload")
        return {"key": "", "url": "", "public_url": None, "size": 0, "content_type": ""}

    bucket = bucket or _bucket()
    content_type = getattr(file_obj, "content_type", "") or "application/octet-stream"
    size = getattr(file_obj, "size", 0) or 0

    if content_type not in ALLOWED_MIME_TYPES:
        raise ValueError(f"File type {content_type} is not allowed")
    if size and size > MAX_FILE_SIZE:
        raise ValueError(f"File too large ({size} bytes); max {MAX_FILE_SIZE} bytes")

    original_name = getattr(file_obj, "name", "upload.bin")
    key = generate_object_key(prefix, original_name)
    upload_url = f"{settings.SUPABASE_URL}/storage/v1/object/{bucket}/{key}"

    file_obj.seek(0)
    resp = requests.post(
        upload_url,
        headers={**_headers(), "Content-Type": content_type, "x-upsert": "true"},
        data=file_obj.read(),
        timeout=30,
    )
    if resp.status_code not in (200, 201):
        logger.error("Supabase upload failed (%s): %s", resp.status_code, resp.text)
        raise IOError(f"Upload failed: {resp.text}")

    public_url = f"{settings.SUPABASE_URL}/storage/v1/object/public/{bucket}/{key}"
    return {
        "key": key,
        "url": public_url,
        "public_url": public_url,
        "size": size,
        "content_type": content_type,
    }


def delete_file(key: str, bucket: str | None = None) -> bool:
    if not is_configured() or not key:
        return False
    bucket = bucket or _bucket()
    delete_url = f"{settings.SUPABASE_URL}/storage/v1/object/{bucket}/{key}"
    try:
        resp = requests.delete(delete_url, headers=_headers(), timeout=15)
        return resp.status_code in (200, 204)
    except Exception as exc:
        logger.warning("Supabase delete failed for %s: %s", key, exc)
        return False


def get_public_url(key: str, bucket: str | None = None) -> str:
    if not key:
        return ""
    bucket = bucket or _bucket()
    return f"{settings.SUPABASE_URL}/storage/v1/object/public/{bucket}/{key}"


def generate_upload_path(instance, filename):
    ext = filename.rsplit(".", 1)[-1] if "." in filename else "bin"
    return f"uploads/{uuid.uuid4()}.{ext}"
