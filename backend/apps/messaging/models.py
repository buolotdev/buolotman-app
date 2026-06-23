from django.db import models
from django.conf import settings


class Conversation(models.Model):
    task = models.ForeignKey('tasks.Task', on_delete=models.SET_NULL, null=True, blank=True, related_name='conversations')
    participants = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='conversations')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_message_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'messaging_conversation'
        indexes = [
            models.Index(fields=['-last_message_at']),
        ]
        ordering = ['-last_message_at']

    def __str__(self):
        return f'Conversation {self.id}'


class Message(models.Model):
    ATTACHMENT_TYPE_CHOICES = (
        ("file", "File"),
        ("image", "Image"),
    )

    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sent_messages')
    text = models.TextField(blank=True, default="")
    attachment_url = models.URLField(max_length=500, blank=True)
    attachment_key = models.CharField(max_length=500, blank=True)
    attachment_name = models.CharField(max_length=255, blank=True)
    attachment_type = models.CharField(max_length=10, choices=ATTACHMENT_TYPE_CHOICES, default="file")
    attachment_size = models.PositiveIntegerField(default=0)
    attachment_content_type = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'messaging_message'
        indexes = [
            models.Index(fields=['conversation']),
            models.Index(fields=['sender']),
            models.Index(fields=['-created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f'Message from {self.sender.email}'
