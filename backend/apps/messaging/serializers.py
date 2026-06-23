from rest_framework import serializers
from .models import Conversation, Message
from apps.accounts.serializers import UserPublicSerializer


class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.SerializerMethodField()
    sender_initials = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = [
            'id',
            'sender',
            'sender_name',
            'sender_initials',
            'text',
            'attachment_url',
            'attachment_key',
            'attachment_name',
            'attachment_type',
            'attachment_size',
            'attachment_content_type',
            'created_at',
            'read_at',
        ]
        read_only_fields = ['id', 'sender', 'created_at']

    def get_sender_name(self, obj):
        return f'{obj.sender.first_name} {obj.sender.last_name}'.strip() or obj.sender.email

    def get_sender_initials(self, obj):
        first = obj.sender.first_name[:1] if obj.sender.first_name else ''
        last = obj.sender.last_name[:1] if obj.sender.last_name else ''
        return (first + last).upper() or obj.sender.email[:2].upper()


class ConversationListSerializer(serializers.ModelSerializer):
    other_participant = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    task_title = serializers.CharField(source='task.title', read_only=True, default='')

    class Meta:
        model = Conversation
        fields = ['id', 'other_participant', 'last_message', 'unread_count', 'task_title', 'last_message_at']
        read_only_fields = ['id', 'last_message_at']

    def get_other_participant(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            other = obj.participants.exclude(id=request.user.id).first()
            if other:
                return {
                    'id': other.id,
                    'name': f'{other.first_name} {other.last_name}'.strip() or other.email,
                    'initials': (other.first_name[:1] if other.first_name else '') + (other.last_name[:1] if other.last_name else ''),
                    'role': other.role,
                }
        return None

    def get_last_message(self, obj):
        last_msg = obj.messages.first()
        if last_msg:
            return {
                'text': last_msg.text[:100],
                'time': last_msg.created_at,
            }
        return None

    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.messages.filter(read_at__isnull=True).exclude(sender=request.user).count()
        return 0


class ConversationDetailSerializer(serializers.ModelSerializer):
    participants = UserPublicSerializer(many=True, read_only=True)
    messages = serializers.SerializerMethodField()
    task_title = serializers.CharField(source='task.title', read_only=True, default='')

    class Meta:
        model = Conversation
        fields = ['id', 'participants', 'messages', 'task_title', 'created_at', 'last_message_at']
        read_only_fields = ['id', 'created_at', 'last_message_at']

    def get_messages(self, obj):
        return MessageSerializer(obj.messages.order_by('created_at'), many=True).data
