from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response

from .models import Notification, AuditLog, Dispute, DisputeEvidence, PlatformSetting, CmsPage
from .serializers import (
    NotificationSerializer,
    AuditLogSerializer,
    DisputeListSerializer,
    DisputeDetailSerializer,
    DisputeCreateSerializer,
    DisputeResolveSerializer,
    DisputeEvidenceSerializer,
    DisputeEvidenceCreateSerializer,
    PlatformSettingSerializer,
    CmsPageSerializer,
)
from .services import create_notification, create_audit_log, notify_users


def _is_admin(user):
    return bool(user and user.is_authenticated and getattr(user, "role", None) == "ADMIN")


def _has_dispute_access(user, dispute):
    if _is_admin(user):
        return True
    return user in [dispute.opened_by, dispute.against, dispute.task.client, dispute.task.assigned_to]


def _is_page_visible_to_public(page):
    return page.is_published


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def notifications(request):
    items = Notification.objects.filter(user=request.user)
    unread = request.query_params.get("unread")
    if unread == "true":
        items = items.filter(is_read=False)
    elif unread == "false":
        items = items.filter(is_read=True)
    serializer = NotificationSerializer(items, many=True)
    return Response(serializer.data)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def mark_notification_read(request, notification_id):
    try:
        notification = Notification.objects.get(id=notification_id, user=request.user)
    except Notification.DoesNotExist:
        return Response({"error": "Notification not found"}, status=status.HTTP_404_NOT_FOUND)

    notification.is_read = True
    notification.read_at = timezone.now()
    notification.save(update_fields=["is_read", "read_at"])
    return Response(NotificationSerializer(notification).data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def disputes(request):
    qs = Dispute.objects.select_related("task", "opened_by", "against", "resolution_by").prefetch_related("evidence")
    if not _is_admin(request.user):
        qs = qs.filter(
            Q(opened_by=request.user)
            | Q(against=request.user)
            | Q(task__client=request.user)
            | Q(task__assigned_to=request.user)
        ).distinct()

    status_filter = request.query_params.get("status")
    if status_filter:
        qs = qs.filter(status=status_filter)

    serializer = DisputeListSerializer(qs.order_by("-opened_at"), many=True)
    return Response(serializer.data)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def dispute_create(request):
    serializer = DisputeCreateSerializer(data=request.data, context={"request": request})
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    task = serializer.validated_data["task"]
    against = serializer.validated_data.get("against") or task.assigned_to

    with transaction.atomic():
        dispute = serializer.save()
        if against and dispute.against_id is None:
            dispute.against = against
            dispute.save(update_fields=["against"])

        create_audit_log(
            actor=request.user,
            action="dispute_created",
            entity_type="dispute",
            entity_id=dispute.id,
            summary=dispute.title,
            metadata={"task_id": task.id, "reason": dispute.reason},
            ip_address=request.META.get("REMOTE_ADDR"),
        )

        recipients = [task.client]
        if task.assigned_to:
            recipients.append(task.assigned_to)
        if against and against not in recipients:
            recipients.append(against)
        notify_users(
            recipients,
            category="dispute",
            title=f"Dispute opened: {dispute.title}",
            body=dispute.description[:240],
            link=f"/dashboard/admin/disputes?d={dispute.id}",
            metadata={"dispute_id": dispute.id, "task_id": task.id},
        )

    return Response(DisputeDetailSerializer(dispute).data, status=status.HTTP_201_CREATED)


@api_view(["GET", "PATCH"])
@permission_classes([IsAuthenticated])
def dispute_detail(request, dispute_id):
    try:
        dispute = Dispute.objects.select_related("task", "opened_by", "against", "resolution_by").prefetch_related("evidence").get(id=dispute_id)
    except Dispute.DoesNotExist:
        return Response({"error": "Dispute not found"}, status=status.HTTP_404_NOT_FOUND)

    if not _has_dispute_access(request.user, dispute):
        return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)

    if request.method == "GET":
        return Response(DisputeDetailSerializer(dispute).data)

    if not _is_admin(request.user):
        return Response({"error": "Admin only"}, status=status.HTTP_403_FORBIDDEN)

    serializer = DisputeResolveSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    with transaction.atomic():
        dispute.status = serializer.validated_data["status"]
        dispute.resolution = serializer.validated_data.get("resolution", dispute.resolution)
        dispute.resolution_by = request.user
        if dispute.status == "resolved":
            dispute.resolved_at = timezone.now()
        dispute.save(update_fields=["status", "resolution", "resolution_by", "resolved_at", "updated_at"])

        create_audit_log(
            actor=request.user,
            action="dispute_updated",
            entity_type="dispute",
            entity_id=dispute.id,
            summary=dispute.title,
            metadata={"status": dispute.status},
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        notify_users(
            [dispute.opened_by] + ([dispute.against] if dispute.against else []),
            category="dispute",
            title=f"Dispute updated: {dispute.title}",
            body=dispute.resolution or dispute.description[:240],
            link=f"/dashboard/admin/disputes?d={dispute.id}",
            metadata={"dispute_id": dispute.id, "status": dispute.status},
        )

    return Response(DisputeDetailSerializer(dispute).data)


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def dispute_evidence(request, dispute_id):
    try:
        dispute = Dispute.objects.select_related("task", "opened_by", "against").get(id=dispute_id)
    except Dispute.DoesNotExist:
        return Response({"error": "Dispute not found"}, status=status.HTTP_404_NOT_FOUND)

    if not _has_dispute_access(request.user, dispute):
        return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)

    if request.method == "GET":
        serializer = DisputeEvidenceSerializer(dispute.evidence.select_related("uploaded_by"), many=True)
        return Response(serializer.data)

    serializer = DisputeEvidenceCreateSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    evidence = serializer.save(dispute=dispute, uploaded_by=request.user)
    create_audit_log(
        actor=request.user,
        action="dispute_evidence_uploaded",
        entity_type="dispute_evidence",
        entity_id=evidence.id,
        summary=evidence.file_name or dispute.title,
        metadata={"dispute_id": dispute.id},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return Response(DisputeEvidenceSerializer(evidence).data, status=status.HTTP_201_CREATED)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def audit_logs(request):
    if not _is_admin(request.user):
        return Response({"error": "Admin only"}, status=status.HTTP_403_FORBIDDEN)

    qs = AuditLog.objects.select_related("actor").all()
    action = request.query_params.get("action")
    entity_type = request.query_params.get("entity_type")
    if action:
        qs = qs.filter(action=action)
    if entity_type:
        qs = qs.filter(entity_type=entity_type)

    page = int(request.query_params.get("page", 1))
    limit = int(request.query_params.get("limit", 50))
    start = (page - 1) * limit
    end = start + limit

    serializer = AuditLogSerializer(qs[start:end], many=True)
    return Response({
        "results": serializer.data,
        "total": qs.count(),
        "page": page,
        "limit": limit,
    })


@api_view(["GET", "POST", "PATCH"])
@permission_classes([IsAuthenticated])
def platform_settings(request):
    if not _is_admin(request.user):
        return Response({"error": "Admin only"}, status=status.HTTP_403_FORBIDDEN)

    if request.method == "GET":
        qs = PlatformSetting.objects.select_related("updated_by").all()
        key = request.query_params.get("key")
        if key:
            qs = qs.filter(key=key)
        serializer = PlatformSettingSerializer(qs, many=True)
        return Response(serializer.data)

    if request.method == "POST":
        serializer = PlatformSettingSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        setting = serializer.save(updated_by=request.user)
        create_audit_log(
            actor=request.user,
            action="platform_setting_created",
            entity_type="platform_setting",
            entity_id=setting.id,
            summary=setting.key,
            metadata={"key": setting.key},
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        return Response(PlatformSettingSerializer(setting).data, status=status.HTTP_201_CREATED)

    key = request.data.get("key")
    if not key:
        return Response({"error": "key is required"}, status=status.HTTP_400_BAD_REQUEST)
    try:
        setting = PlatformSetting.objects.get(key=key)
    except PlatformSetting.DoesNotExist:
        return Response({"error": "Setting not found"}, status=status.HTTP_404_NOT_FOUND)

    serializer = PlatformSettingSerializer(setting, data=request.data, partial=True)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    setting = serializer.save(updated_by=request.user)
    create_audit_log(
        actor=request.user,
        action="platform_setting_updated",
        entity_type="platform_setting",
        entity_id=setting.id,
        summary=setting.key,
        metadata={"key": setting.key},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return Response(PlatformSettingSerializer(setting).data)


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def cms_pages(request):
    if not _is_admin(request.user):
        return Response({"error": "Admin only"}, status=status.HTTP_403_FORBIDDEN)

    if request.method == "GET":
        qs = CmsPage.objects.select_related("updated_by").all()
        serializer = CmsPageSerializer(qs, many=True)
        return Response(serializer.data)

    serializer = CmsPageSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    page = serializer.save(updated_by=request.user)
    create_audit_log(
        actor=request.user,
        action="cms_page_created",
        entity_type="cms_page",
        entity_id=page.id,
        summary=page.title,
        metadata={"slug": page.slug, "is_published": page.is_published},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return Response(CmsPageSerializer(page).data, status=status.HTTP_201_CREATED)


@api_view(["GET", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def cms_page_detail(request, page_id):
    if not _is_admin(request.user):
        return Response({"error": "Admin only"}, status=status.HTTP_403_FORBIDDEN)

    try:
        page = CmsPage.objects.select_related("updated_by").get(id=page_id)
    except CmsPage.DoesNotExist:
        return Response({"error": "Page not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == "GET":
        return Response(CmsPageSerializer(page).data)

    if request.method == "DELETE":
        title = page.title
        page.delete()
        create_audit_log(
            actor=request.user,
            action="cms_page_deleted",
            entity_type="cms_page",
            entity_id=page_id,
            summary=title,
            metadata={},
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        return Response(status=status.HTTP_204_NO_CONTENT)

    serializer = CmsPageSerializer(page, data=request.data, partial=True)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    page = serializer.save(updated_by=request.user)
    create_audit_log(
        actor=request.user,
        action="cms_page_updated",
        entity_type="cms_page",
        entity_id=page.id,
        summary=page.title,
        metadata={"slug": page.slug, "is_published": page.is_published},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return Response(CmsPageSerializer(page).data)


@api_view(["GET"])
@permission_classes([AllowAny])
def public_cms_pages(request):
    qs = CmsPage.objects.filter(is_published=True, show_in_footer=True).order_by("sort_order", "title")
    serializer = CmsPageSerializer(qs, many=True)
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([AllowAny])
def public_cms_page_detail(request, slug):
    try:
        page = CmsPage.objects.get(slug=slug, is_published=True)
    except CmsPage.DoesNotExist:
        return Response({"error": "Page not found"}, status=status.HTTP_404_NOT_FOUND)
    return Response(CmsPageSerializer(page).data)
