from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from apps.tasks.models import Task, Category
from apps.governance.models import Dispute, Notification, CmsPage

User = get_user_model()

class GovernanceAPITests(APITestCase):
    def setUp(self):
        self.client_user = User.objects.create_user(
            username="client@test.com",
            email="client@test.com",
            password="password123",
            role="CLIENT",
            first_name="John",
            last_name="Doe"
        )
        self.tech_user = User.objects.create_user(
            username="tech@test.com",
            email="tech@test.com",
            password="password123",
            role="TECHNICIAN",
            first_name="Jane",
            last_name="Technician"
        )
        self.admin_user = User.objects.create_user(
            username="admin@test.com",
            email="admin@test.com",
            password="password123",
            role="ADMIN",
            first_name="Super",
            last_name="Admin"
        )
        self.category = Category.objects.create(name="Plumbing", slug="plumbing")
        self.task = Task.objects.create(
            title="Leaking Pipe",
            description="Leaky pipe under basin",
            category=self.category,
            client=self.client_user,
            assigned_to=self.tech_user,
            status="in_progress"
        )

    def test_disputes_flow(self):
        self.client.force_authenticate(user=self.client_user)

        # Create dispute
        create_url = reverse("dispute_create")
        data = {
            "task": self.task.id,
            "against": self.tech_user.id,
            "reason": "quality",
            "title": "Poor quality of work",
            "description": "Technician damaged the pipe more."
        }
        response = self.client.post(create_url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        dispute_id = response.data["id"]

        # List disputes
        list_url = reverse("disputes")
        response = self.client.get(list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        # Upload evidence
        evidence_url = reverse("dispute_evidence", kwargs={"dispute_id": dispute_id})
        evidence_data = {
            "file_url": "https://supabase-r2.com/evidence1.jpg",
            "file_name": "evidence1.jpg",
            "file_type": "image",
            "content_type": "image/jpeg",
            "note": "Here is the photo of the leakage."
        }
        response = self.client.post(evidence_url, evidence_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        # Resolve dispute (Admin required)
        self.client.force_authenticate(user=self.admin_user)
        detail_url = reverse("dispute_detail", kwargs={"dispute_id": dispute_id})
        resolve_data = {
            "status": "resolved",
            "resolution": "Refund issued to client."
        }
        response = self.client.patch(detail_url, resolve_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "resolved")

    def test_notifications(self):
        # Create a mock notification
        Notification.objects.create(
            user=self.client_user,
            category="system",
            title="System Alert",
            body="Maintenance update planned."
        )

        self.client.force_authenticate(user=self.client_user)
        url = reverse("notifications")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        notification_id = response.data[0]["id"]

        # Mark as read
        read_url = reverse("mark_notification_read", kwargs={"notification_id": notification_id})
        response = self.client.post(read_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["is_read"])

    def test_cms_pages_flow(self):
        self.client.force_authenticate(user=self.admin_user)

        create_url = reverse("cms_pages")
        payload = {
            "title": "Privacy Policy",
            "slug": "privacy",
            "excerpt": "How we handle data.",
            "content": "Privacy content",
            "is_published": True,
            "show_in_footer": True,
            "sort_order": 1,
        }
        response = self.client.post(create_url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        page_id = response.data["id"]

        list_url = reverse("cms_pages")
        response = self.client.get(list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        public_list = reverse("public_cms_pages")
        self.client.force_authenticate(user=None)
        response = self.client.get(public_list)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        public_detail = reverse("public_cms_page_detail", kwargs={"slug": "privacy"})
        response = self.client.get(public_detail)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "Privacy Policy")

        self.client.force_authenticate(user=self.admin_user)
        detail_url = reverse("cms_page_detail", kwargs={"page_id": page_id})
        response = self.client.patch(detail_url, {"title": "Updated Privacy Policy"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "Updated Privacy Policy")

        response = self.client.delete(detail_url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
