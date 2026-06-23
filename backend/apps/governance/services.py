from django.db import transaction

from .models import Notification, AuditLog


def create_notification(*, user, category, title, body="", link="", metadata=None):
    if user is None:
        return None
    return Notification.objects.create(
        user=user,
        category=category,
        title=title,
        body=body,
        link=link,
        metadata=metadata or {},
    )


def create_audit_log(*, actor=None, action, entity_type, entity_id="", summary="", metadata=None, ip_address=None):
    return AuditLog.objects.create(
        actor=actor,
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id is not None else "",
        summary=summary,
        metadata=metadata or {},
        ip_address=ip_address,
    )


def notify_users(users, **kwargs):
    created = []
    for user in users:
        created.append(create_notification(user=user, **kwargs))
    return created
