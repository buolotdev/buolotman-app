from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.utils import timezone

from apps.governance.services import create_notification, create_audit_log
from utils.storage import upload_file

from .models import Conversation, Message
from .serializers import ConversationListSerializer, ConversationDetailSerializer, MessageSerializer


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def conversation_list(request):
    conversations = Conversation.objects.filter(participants=request.user).prefetch_related('participants', 'messages', 'task')
    serializer = ConversationListSerializer(conversations, many=True, context={'request': request})
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def conversation_detail(request, conversation_id):
    try:
        conversation = Conversation.objects.prefetch_related('participants', 'messages__sender', 'task').get(id=conversation_id)
    except Conversation.DoesNotExist:
        return Response({"error": "Conversation not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.user not in conversation.participants.all():
        return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)

    conversation.messages.filter(read_at__isnull=True).exclude(sender=request.user).update(read_at=timezone.now())

    serializer = ConversationDetailSerializer(conversation)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_message(request, conversation_id):
    try:
        conversation = Conversation.objects.get(id=conversation_id)
    except Conversation.DoesNotExist:
        return Response({"error": "Conversation not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.user not in conversation.participants.all():
        return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)

    payload = request.data.copy()
    if hasattr(payload, "getlist"):
        payload = payload.dict()
    serializer = MessageSerializer(data=payload)
    if serializer.is_valid():
        message = serializer.save(conversation=conversation, sender=request.user)
        conversation.last_message_at = timezone.now()
        conversation.save(update_fields=['last_message_at'])
        recipients = [user for user in conversation.participants.all() if user != request.user]
        for recipient in recipients:
            create_notification(
                user=recipient,
                category="message",
                title="New message",
                body=(message.text or message.attachment_name or "New message")[:240],
                link=f"/dashboard/client/messages?c={conversation.id}",
                metadata={"conversation_id": conversation.id, "message_id": message.id},
            )
        create_audit_log(
            actor=request.user,
            action="message_sent",
            entity_type="conversation",
            entity_id=conversation.id,
            summary="Message sent",
            metadata={"message_id": message.id},
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        return Response(MessageSerializer(message).data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def upload_message_attachment(request, conversation_id):
    try:
        conversation = Conversation.objects.get(id=conversation_id)
    except Conversation.DoesNotExist:
        return Response({"error": "Conversation not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.user not in conversation.participants.all():
        return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)

    file_obj = request.FILES.get("file") or request.FILES.get("attachment")
    if not file_obj:
        return Response({"error": "No file provided"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        result = upload_file(file_obj, prefix=f"messages/{conversation_id}")
    except ValueError as exc:
        return Response({"error": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as exc:
        return Response({"error": f"Upload failed: {exc}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    if not result.get("public_url"):
        return Response({"error": "File storage is not configured."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    return Response({
        "url": result["public_url"],
        "key": result["key"],
        "name": file_obj.name,
        "size": result["size"],
        "content_type": result["content_type"],
        "type": "image" if (result.get("content_type") or "").startswith("image/") else "file",
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_conversation(request):
    participant_id = request.data.get('participant_id')
    task_id = request.data.get('task_id')

    if not participant_id:
        return Response({"error": "participant_id is required"}, status=status.HTTP_400_BAD_REQUEST)

    from django.contrib.auth import get_user_model
    User = get_user_model()
    try:
        participant = User.objects.get(id=participant_id)
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

    existing = Conversation.objects.filter(participants=request.user).filter(participants=participant)
    if task_id:
        existing = existing.filter(task_id=task_id)
    conversation = existing.first()

    if conversation:
        return Response(ConversationDetailSerializer(conversation).data)

    conversation = Conversation.objects.create(task_id=task_id)
    conversation.participants.add(request.user, participant)
    create_audit_log(
        actor=request.user,
        action="conversation_created",
        entity_type="conversation",
        entity_id=conversation.id,
        summary="Conversation created",
        metadata={"participant_id": participant.id, "task_id": task_id},
        ip_address=request.META.get("REMOTE_ADDR"),
    )
    return Response(ConversationDetailSerializer(conversation).data, status=status.HTTP_201_CREATED)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def mark_read(request, conversation_id):
    try:
        conversation = Conversation.objects.get(id=conversation_id)
    except Conversation.DoesNotExist:
        return Response({"error": "Conversation not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.user not in conversation.participants.all():
        return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)

    updated = conversation.messages.filter(read_at__isnull=True).exclude(sender=request.user).update(read_at=timezone.now())
    return Response({"marked_read": updated})
