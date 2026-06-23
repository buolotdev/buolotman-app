"""
File upload endpoints for avatars, portfolio items, and task attachments.
"""
import os
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes, throttle_classes
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from utils.storage import upload_file, delete_file
from utils.rate_limit import UploadThrottle


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
@throttle_classes([UploadThrottle])
def upload_avatar(request):
    file_obj = request.FILES.get("file") or request.FILES.get("avatar")
    if not file_obj:
        return Response({"error": "No file provided. Use 'file' or 'avatar' field."}, status=400)

    try:
        result = upload_file(file_obj, prefix=f"avatars/{request.user.id}")
    except ValueError as exc:
        return Response({"error": str(exc)}, status=400)
    except Exception as exc:
        return Response({"error": f"Upload failed: {exc}"}, status=500)

    if not result.get("public_url"):
        return Response({"error": "File storage is not configured."}, status=503)

    request.user.avatar_url = result["public_url"]
    request.user.save(update_fields=["avatar_url"])

    return Response({
        "message": "Avatar uploaded successfully",
        "avatar_url": result["public_url"],
        "size": result["size"],
    }, status=201)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
@throttle_classes([UploadThrottle])
def upload_portfolio_image(request):
    file_obj = request.FILES.get("file") or request.FILES.get("image")
    if not file_obj:
        return Response({"error": "No file provided. Use 'file' or 'image' field."}, status=400)

    try:
        result = upload_file(file_obj, prefix=f"portfolio/{request.user.id}")
    except ValueError as exc:
        return Response({"error": str(exc)}, status=400)
    except Exception as exc:
        return Response({"error": f"Upload failed: {exc}"}, status=500)

    if not result.get("public_url"):
        return Response({"error": "File storage is not configured."}, status=503)

    return Response({
        "message": "Portfolio image uploaded successfully",
        "image_url": result["public_url"],
        "key": result["key"],
        "size": result["size"],
    }, status=201)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
@throttle_classes([UploadThrottle])
def upload_task_attachment(request, task_id):
    from apps.tasks.models import Task, TaskAttachment
    try:
        task = Task.objects.get(id=task_id)
    except Task.DoesNotExist:
        return Response({"error": "Task not found"}, status=404)

    if task.client_id != request.user.id:
        return Response({"error": "Only the task owner can attach files"}, status=403)

    file_obj = request.FILES.get("file") or request.FILES.get("attachment")
    if not file_obj:
        return Response({"error": "No file provided"}, status=400)

    try:
        result = upload_file(file_obj, prefix=f"tasks/{task_id}")
    except ValueError as exc:
        return Response({"error": str(exc)}, status=400)
    except Exception as exc:
        return Response({"error": f"Upload failed: {exc}"}, status=500)

    if not result.get("public_url"):
        return Response({"error": "File storage is not configured."}, status=503)

    attachment = TaskAttachment.objects.create(
        task=task,
        file_url=result["public_url"],
        storage_key=result["key"],
        file_name=file_obj.name,
        content_type=result["content_type"],
        file_size=result["size"],
        uploaded_by=request.user,
    )

    return Response({
        "message": "Attachment uploaded successfully",
        "id": attachment.id,
        "file_url": result["public_url"],
        "file_name": file_obj.name,
        "size": result["size"],
    }, status=201)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_upload(request, key):
    success = delete_file(key)
    if success:
        return Response({"message": "Deleted"}, status=204)
    return Response({"error": "Delete failed or file not found"}, status=400)
