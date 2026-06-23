from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from apps.tasks.models import Task, Category
from apps.accounts.models import TechnicianService

User = get_user_model()

class SearchAPITests(APITestCase):
    def setUp(self):
        self.client_user = User.objects.create_user(
            username="client@test.com",
            email="client@test.com",
            password="password123",
            role="CLIENT"
        )
        self.tech_user = User.objects.create_user(
            username="tech@test.com",
            email="tech@test.com",
            password="password123",
            role="TECHNICIAN",
            first_name="Jane",
            last_name="Technician",
            country="Senegal"
        )
        self.category = Category.objects.create(name="Plumbing", slug="plumbing")
        self.task = Task.objects.create(
            title="Urgent plumbing repair",
            description="Leaky pipe repair",
            category=self.category,
            client=self.client_user,
            status="open",
            budget_min=1000,
            budget_max=5000,
            city="Dakar",
            location="Dakar, Senegal"
        )
        TechnicianService.objects.create(
            technician=self.tech_user,
            title="Premium Plumbing",
            category=self.category,
            description="Pipe repairs and installations",
            service_type="onsite",
            coverage_area="Dakar",
            pricing_model="fixed",
            pricing_min=2000,
            pricing_max=5000,
        )

    def test_global_search(self):
        url = reverse("search")
        
        # Test searching for tasks with query 'plumbing'
        response = self.client.get(url, {"q": "plumbing", "tab": "tasks"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["total"], 1)
        self.assertEqual(response.data["results"][0]["title"], "Urgent plumbing repair")

        # Test searching with location Senegal
        response = self.client.get(url, {"location": "Senegal"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["total"], 3)  # task + technician + technician service coverage area

        # Test searching with category slug 'plumbing'
        response = self.client.get(url, {"category": "plumbing", "tab": "tasks"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["total"], 1)

        response = self.client.get(url, {"q": "plumbing", "tab": "services"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(response.data["total"], 1)
        self.assertEqual(response.data["results"][0]["type"], "service")
