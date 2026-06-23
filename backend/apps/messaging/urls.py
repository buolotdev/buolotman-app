from django.urls import path
from . import views

urlpatterns = [
    path('conversations/', views.conversation_list, name='conversation_list'),
    path('conversations/create/', views.create_conversation, name='create_conversation'),
    path('conversations/<int:conversation_id>/', views.conversation_detail, name='conversation_detail'),
    path('conversations/<int:conversation_id>/messages/', views.send_message, name='send_message'),
    path('conversations/<int:conversation_id>/attachments/', views.upload_message_attachment, name='upload_message_attachment'),
    path('conversations/<int:conversation_id>/read/', views.mark_read, name='mark_read'),
]
