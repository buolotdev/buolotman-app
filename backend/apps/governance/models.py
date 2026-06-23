from django.conf import settings
from django.db import models


class Notification(models.Model):
    CATEGORY_CHOICES = (
        ("task", "Task"),
        ("bid", "Bid"),
        ("message", "Message"),
        ("payment", "Payment"),
        ("dispute", "Dispute"),
        ("verification", "Verification"),
        ("system", "System"),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications")
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default="system")
    title = models.CharField(max_length=255)
    body = models.TextField(blank=True)
    link = models.CharField(max_length=500, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "governance_notification"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user"]),
            models.Index(fields=["category"]),
            models.Index(fields=["is_read"]),
            models.Index(fields=["-created_at"]),
        ]

    def __str__(self):
        return f"{self.title} -> {self.user.email}"


class AuditLog(models.Model):
    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="audit_logs")
    action = models.CharField(max_length=100)
    entity_type = models.CharField(max_length=100)
    entity_id = models.CharField(max_length=100, blank=True)
    summary = models.CharField(max_length=255, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "governance_audit_log"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["action"]),
            models.Index(fields=["entity_type"]),
            models.Index(fields=["-created_at"]),
        ]

    def __str__(self):
        return f"{self.action} {self.entity_type}:{self.entity_id}"


class Dispute(models.Model):
    STATUS_CHOICES = (
        ("open", "Open"),
        ("under_review", "Under Review"),
        ("awaiting_response", "Awaiting Response"),
        ("resolved", "Resolved"),
        ("closed", "Closed"),
    )
    REASON_CHOICES = (
        ("payment", "Payment"),
        ("quality", "Quality of Work"),
        ("behavior", "Behavior"),
        ("scam", "Scam / Fraud"),
        ("other", "Other"),
    )

    task = models.ForeignKey("tasks.Task", on_delete=models.CASCADE, related_name="disputes")
    opened_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="opened_disputes")
    against = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="disputes_against")
    reason = models.CharField(max_length=20, choices=REASON_CHOICES, default="other")
    title = models.CharField(max_length=255)
    description = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="open")
    resolution = models.TextField(blank=True)
    resolution_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="resolved_disputes")
    opened_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "governance_dispute"
        ordering = ["-opened_at"]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["reason"]),
            models.Index(fields=["-opened_at"]),
        ]

    def __str__(self):
        return f"Dispute #{self.id} - {self.title}"


class DisputeEvidence(models.Model):
    FILE_TYPE_CHOICES = (
        ("image", "Image"),
        ("file", "File"),
        ("link", "Link"),
    )

    dispute = models.ForeignKey(Dispute, on_delete=models.CASCADE, related_name="evidence")
    uploaded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="dispute_evidence")
    file_url = models.URLField(max_length=500, blank=True)
    storage_key = models.CharField(max_length=500, blank=True)
    file_name = models.CharField(max_length=255, blank=True)
    file_type = models.CharField(max_length=10, choices=FILE_TYPE_CHOICES, default="file")
    content_type = models.CharField(max_length=100, blank=True)
    note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "governance_dispute_evidence"
        ordering = ["created_at"]

    def __str__(self):
        return self.file_name or f"Evidence for dispute {self.dispute_id}"


class PlatformSetting(models.Model):
    key = models.CharField(max_length=100, unique=True)
    value = models.JSONField(default=dict, blank=True)
    description = models.CharField(max_length=255, blank=True)
    is_sensitive = models.BooleanField(default=False)
    updated_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name="updated_platform_settings")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "governance_platform_setting"
        ordering = ["key"]

    def __str__(self):
        return self.key


class CmsPage(models.Model):
    title = models.CharField(max_length=255)
    slug = models.SlugField(unique=True)
    excerpt = models.CharField(max_length=300, blank=True)
    content = models.TextField(blank=True)
    is_published = models.BooleanField(default=False)
    show_in_footer = models.BooleanField(default=True)
    sort_order = models.PositiveIntegerField(default=0)
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="updated_cms_pages",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "governance_cms_page"
        ordering = ["sort_order", "title"]
        indexes = [
            models.Index(fields=["is_published"]),
            models.Index(fields=["show_in_footer"]),
            models.Index(fields=["slug"]),
        ]

    def __str__(self):
        return self.title
