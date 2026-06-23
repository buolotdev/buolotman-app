from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from apps.tasks.models import Task, Bid, Question, Category, Skill

User = get_user_model()

class TasksAPITests(APITestCase):
    def setUp(self):
        # Create standard test users
        self.client_user = User.objects.create_user(
            username="client@test.com",
            email="client@test.com",
            password="password123",
            role="CLIENT",
            first_name="John",
            last_name="Doe",
            phone="+1234567890"
        )
        self.tech_user = User.objects.create_user(
            username="tech@test.com",
            email="tech@test.com",
            password="password123",
            role="TECHNICIAN",
            first_name="Jane",
            last_name="Technician",
            phone="+1987654321"
        )
        
        # Create a category
        self.category = Category.objects.create(
            name="Plumbing",
            slug="plumbing",
            icon="water",
            is_active=True
        )

        # Create a task
        self.task = Task.objects.create(
            title="Fix leaky kitchen sink pipe",
            description="The pipe under my kitchen sink is leaking water. Need immediate repair.",
            category=self.category,
            client=self.client_user,
            status="open",
            budget_min=5000,
            budget_max=15000,
            budget_mode="fixed"
        )

    def test_category_list(self):
        url = reverse("category_list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], "Plumbing")

    def test_category_update(self):
        self.client_user.role = "ADMIN"
        self.client_user.save(update_fields=["role"])
        self.client.force_authenticate(user=self.client_user)
        url = reverse("category_detail", kwargs={"category_id": self.category.id})
        response = self.client.patch(url, {"name": "Water Systems", "slug": "water-systems"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["name"], "Water Systems")
        self.assertEqual(response.data["slug"], "water-systems")

    def test_task_list(self):
        url = reverse("task_list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("results", response.data)
        self.assertEqual(response.data["total"], 1)

    def test_task_create(self):
        self.client.force_authenticate(user=self.client_user)
        url = reverse("task_create")
        data = {
            "title": "Paint my living room walls",
            "description": "Light grey color. Will provide brushes and paint.",
            "category": self.category.id,
            "budget_min": 20000,
            "budget_max": 40000,
            "budget_mode": "fixed",
            "urgency": "standard",
            "service_type": "onsite",
            "location": "Dakar, Senegal",
            "city": "Dakar"
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["title"], "Paint my living room walls")

    def test_task_detail_and_patch(self):
        self.client.force_authenticate(user=self.client_user)
        url = reverse("task_detail", kwargs={"task_id": self.task.id})
        
        # Get detail
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], self.task.title)

        # Patch detail
        patch_data = {"title": "Updated sink leak repair request"}
        response = self.client.patch(url, patch_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "Updated sink leak repair request")

    def test_task_bidding(self):
        # Authenticate as technician
        self.client.force_authenticate(user=self.tech_user)
        url = reverse("task_bids", kwargs={"task_id": self.task.id})

        # Submit bid
        bid_data = {
            "amount": 7500.00,
            "amount_type": "fixed",
            "message": "I can do this in 2 hours.",
            "duration": "2 hours",
            "extra_notes": "None"
        }
        response = self.client.post(url, bid_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        bid_id = response.data["id"]

        # Get bids for task
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        # Accept bid (client authorization required)
        self.client.force_authenticate(user=self.client_user)
        accept_url = reverse("bid_detail", kwargs={"bid_id": bid_id})
        response = self.client.patch(accept_url, {"status": "accepted"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "accepted")

    def test_task_questions(self):
        self.client.force_authenticate(user=self.tech_user)
        url = reverse("task_questions", kwargs={"task_id": self.task.id})
        
        # Post question
        response = self.client.post(url, {"text": "Do I need to buy pipes?"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        # List questions
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["text"], "Do I need to buy pipes?")
