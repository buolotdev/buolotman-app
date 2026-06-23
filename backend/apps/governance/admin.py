from django.contrib import admin

from .models import Notification, AuditLog, Dispute, DisputeEvidence, PlatformSetting, CmsPage


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "category", "title", "is_read", "created_at")
    list_filter = ("category", "is_read", "created_at")
    search_fields = ("title", "body", "user__email")


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ("id", "action", "entity_type", "entity_id", "actor", "created_at")
    list_filter = ("action", "entity_type", "created_at")
    search_fields = ("action", "entity_type", "entity_id", "summary")


@admin.register(Dispute)
class DisputeAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "status", "reason", "task", "opened_by", "resolved_at")
    list_filter = ("status", "reason", "opened_at")
    search_fields = ("title", "description", "task__title", "opened_by__email")


@admin.register(DisputeEvidence)
class DisputeEvidenceAdmin(admin.ModelAdmin):
    list_display = ("id", "dispute", "uploaded_by", "file_name", "file_type", "created_at")
    list_filter = ("file_type", "created_at")
    search_fields = ("file_name", "note")


@admin.register(PlatformSetting)
class PlatformSettingAdmin(admin.ModelAdmin):
    list_display = ("key", "is_sensitive", "updated_by", "updated_at")
    list_filter = ("is_sensitive", "updated_at")
    search_fields = ("key", "description")


@admin.register(CmsPage)
class CmsPageAdmin(admin.ModelAdmin):
    list_display = ("title", "slug", "is_published", "show_in_footer", "sort_order", "updated_by", "updated_at")
    list_filter = ("is_published", "show_in_footer")
    search_fields = ("title", "slug", "excerpt", "content")
    prepopulated_fields = {"slug": ("title",)}
