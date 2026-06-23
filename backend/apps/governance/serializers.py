from django.utils import timezone
from rest_framework import serializers

from .models import Notification, AuditLog, Dispute, DisputeEvidence, PlatformSetting, CmsPage


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "category", "title", "body", "link", "metadata", "is_read", "created_at", "read_at"]
        read_only_fields = fields


class AuditLogSerializer(serializers.ModelSerializer):
    actor_name = serializers.SerializerMethodField()

    class Meta:
        model = AuditLog
        fields = ["id", "actor", "actor_name", "action", "entity_type", "entity_id", "summary", "metadata", "ip_address", "created_at"]
        read_only_fields = fields

    def get_actor_name(self, obj):
        if not obj.actor:
            return "System"
        return obj.actor.get_full_name() or obj.actor.email


class DisputeEvidenceSerializer(serializers.ModelSerializer):
    uploaded_by_name = serializers.SerializerMethodField()

    class Meta:
        model = DisputeEvidence
        fields = [
            "id",
            "dispute",
            "uploaded_by",
            "uploaded_by_name",
            "file_url",
            "storage_key",
            "file_name",
            "file_type",
            "content_type",
            "note",
            "created_at",
        ]
        read_only_fields = ["id", "dispute", "uploaded_by", "uploaded_by_name", "created_at"]

    def get_uploaded_by_name(self, obj):
        return obj.uploaded_by.get_full_name() or obj.uploaded_by.email


class DisputeListSerializer(serializers.ModelSerializer):
    opened_by_name = serializers.SerializerMethodField()
    against_name = serializers.SerializerMethodField()
    evidence_count = serializers.SerializerMethodField()
    task_title = serializers.CharField(source='task.title', read_only=True)
    task_budget = serializers.DecimalField(source='task.budget_max', max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = Dispute
        fields = [
            "id",
            "task",
            "task_title",
            "task_budget",
            "opened_by",
            "opened_by_name",
            "against",
            "against_name",
            "reason",
            "title",
            "status",
            "evidence_count",
            "opened_at",
            "updated_at",
            "resolved_at",
        ]
        read_only_fields = fields

    def get_opened_by_name(self, obj):
        return obj.opened_by.get_full_name() or obj.opened_by.email

    def get_against_name(self, obj):
        if not obj.against:
            return ""
        return obj.against.get_full_name() or obj.against.email

    def get_evidence_count(self, obj):
        return obj.evidence.count()


class DisputeDetailSerializer(serializers.ModelSerializer):
    opened_by_name = serializers.SerializerMethodField()
    against_name = serializers.SerializerMethodField()
    resolution_by_name = serializers.SerializerMethodField()
    evidence = DisputeEvidenceSerializer(many=True, read_only=True)
    task_title = serializers.CharField(source='task.title', read_only=True)
    task_budget = serializers.DecimalField(source='task.budget_max', max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = Dispute
        fields = [
            "id",
            "task",
            "task_title",
            "task_budget",
            "opened_by",
            "opened_by_name",
            "against",
            "against_name",
            "reason",
            "title",
            "description",
            "status",
            "resolution",
            "resolution_by",
            "resolution_by_name",
            "opened_at",
            "updated_at",
            "resolved_at",
            "evidence",
        ]
        read_only_fields = ["id", "task_title", "task_budget", "opened_by", "opened_by_name", "against_name", "resolution_by", "resolution_by_name", "opened_at", "updated_at", "resolved_at", "evidence"]

    def get_opened_by_name(self, obj):
        return obj.opened_by.get_full_name() or obj.opened_by.email

    def get_against_name(self, obj):
        if not obj.against:
            return ""
        return obj.against.get_full_name() or obj.against.email

    def get_resolution_by_name(self, obj):
        if not obj.resolution_by:
            return ""
        return obj.resolution_by.get_full_name() or obj.resolution_by.email


class DisputeCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Dispute
        fields = ["task", "against", "reason", "title", "description"]

    def validate(self, attrs):
        request = self.context["request"]
        task = attrs["task"]
        if request.user not in [task.client, task.assigned_to]:
            raise serializers.ValidationError("Only task participants can open a dispute.")
        return attrs

    def create(self, validated_data):
        request = self.context["request"]
        dispute = Dispute.objects.create(opened_by=request.user, **validated_data)
        return dispute


class DisputeResolveSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=["under_review", "awaiting_response", "resolved", "closed"])
    resolution = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        if attrs["status"] == "resolved" and not attrs.get("resolution"):
            raise serializers.ValidationError({"resolution": "Resolution text is required when resolving a dispute."})
        return attrs


class DisputeEvidenceCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = DisputeEvidence
        fields = ["file_url", "storage_key", "file_name", "file_type", "content_type", "note"]

    def validate(self, attrs):
        if not attrs.get("file_url") and attrs.get("file_type") != "link":
            raise serializers.ValidationError({"file_url": "file_url is required unless this evidence is a link."})
        return attrs


class PlatformSettingSerializer(serializers.ModelSerializer):
    updated_by_name = serializers.SerializerMethodField()

    class Meta:
        model = PlatformSetting
        fields = ["id", "key", "value", "description", "is_sensitive", "updated_by", "updated_by_name", "created_at", "updated_at"]
        read_only_fields = ["id", "updated_by", "updated_by_name", "created_at", "updated_at"]

    def get_updated_by_name(self, obj):
        if not obj.updated_by:
            return ""
        return obj.updated_by.get_full_name() or obj.updated_by.email


class CmsPageSerializer(serializers.ModelSerializer):
    updated_by_name = serializers.SerializerMethodField()

    class Meta:
        model = CmsPage
        fields = [
            "id",
            "title",
            "slug",
            "excerpt",
            "content",
            "is_published",
            "show_in_footer",
            "sort_order",
            "updated_by",
            "updated_by_name",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "updated_by", "updated_by_name", "created_at", "updated_at"]

    def get_updated_by_name(self, obj):
        if not obj.updated_by:
            return ""
        return obj.updated_by.get_full_name() or obj.updated_by.email
