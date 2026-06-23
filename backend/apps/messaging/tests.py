from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from apps.messaging.models import Conversation, Message

User = get_user_model()

class MessagingAPITests(APITestCase):
    def setUp(self):
        self.user1 = User.objects.create_user(
            username="user1@test.com",
            email="user1@test.com",
            password="password123",
            first_name="User",
            last_name="One"
        )
        self.user2 = User.objects.create_user(
            username="user2@test.com",
            email="user2@test.com",
            password="password123",
            first_name="User",
            last_name="Two"
        )

    def test_create_and_manage_conversation(self):
        self.client.force_authenticate(user=self.user1)

        # Create conversation
        create_url = reverse("create_conversation")
        data = {"participant_id": self.user2.id}
        response = self.client.post(create_url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        conversation_id = response.data["id"]

        # List conversations
        list_url = reverse("conversation_list")
        response = self.client.get(list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        # Send message
        send_url = reverse("send_message", kwargs={"conversation_id": conversation_id})
        message_data = {"text": "Hello User Two!"}
        response = self.client.post(send_url, message_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["text"], "Hello User Two!")

        # Retrieve conversation details
        detail_url = reverse("conversation_detail", kwargs={"conversation_id": conversation_id})
        response = self.client.get(detail_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["messages"]), 1)

        # Mark read (by User Two)
        self.client.force_authenticate(user=self.user2)
        mark_url = reverse("mark_read", kwargs={"conversation_id": conversation_id})
        response = self.client.patch(mark_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["marked_read"], 1)

    def test_send_message_with_attachment_metadata(self):
        self.client.force_authenticate(user=self.user1)
        conversation = Conversation.objects.create()
        conversation.participants.add(self.user1, self.user2)

        send_url = reverse("send_message", kwargs={"conversation_id": conversation.id})
        response = self.client.post(send_url, {
            "text": "",
            "attachment_url": "https://example.com/file.pdf",
            "attachment_name": "file.pdf",
            "attachment_type": "file",
            "attachment_size": 1024,
            "attachment_content_type": "application/pdf",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["attachment_name"], "file.pdf")
