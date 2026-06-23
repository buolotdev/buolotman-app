from django.contrib import admin
from .models import Conversation, Message


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'task', 'last_message_at', 'created_at')
    filter_horizontal = ('participants',)
    raw_id_fields = ('task',)


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('conversation', 'sender', 'text', 'created_at', 'read_at')
    list_filter = ('created_at',)
    search_fields = ('sender__email', 'text')
    raw_id_fields = ('conversation', 'sender')
