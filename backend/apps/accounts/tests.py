from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from apps.accounts.models import SavedProfessional, PhoneOTPChallenge
from apps.tasks.models import Category

User = get_user_model()

class AccountsAPITests(APITestCase):
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
        self.admin_user = User.objects.create_user(
            username="admin@test.com",
            email="admin@test.com",
            password="password123",
            role="ADMIN",
            first_name="Super",
            last_name="Admin"
        )
        self.category = Category.objects.create(name="Electrical", slug="electrical")

    def test_client_registration(self):
        url = reverse("register_client")
        data = {
            "first_name": "New",
            "last_name": "Client",
            "email": "newclient@test.com",
            "password": "newpassword123",
            "phone": "+111222333"
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(User.objects.filter(email="newclient@test.com").exists())

    def test_technician_registration(self):
        url = reverse("register_technician")
        data = {
            "first_name": "New",
            "last_name": "Tech",
            "email": "newtech@test.com",
            "password": "newpassword123",
            "phone": "+222333444"
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(email="newtech@test.com")
        self.assertEqual(user.role, "TECHNICIAN")
        self.assertTrue(hasattr(user, "technician_profile"))

    def test_login_jwt(self):
        url = reverse("token_obtain_pair")
        data = {
            "username": "client@test.com",
            "password": "password123"
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)
        self.assertEqual(response.data["role"], "CLIENT")

    def test_get_me_details(self):
        self.client.force_authenticate(user=self.client_user)
        url = reverse("me")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["email"], "client@test.com")

    def test_saved_professionals(self):
        self.client.force_authenticate(user=self.client_user)
        # Add tech to saved list
        url = reverse("saved_professionals")
        data = {"professional_id": self.tech_user.id}
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        # Get saved professionals list
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        # Delete saved professional
        delete_url = reverse("saved_professional_detail", kwargs={"professional_id": self.tech_user.id})
        response = self.client.delete(delete_url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

    def test_admin_suspend_user(self):
        self.client.force_authenticate(user=self.admin_user)
        url = reverse("admin_suspend_user", kwargs={"user_id": self.client_user.id})
        # Suspend
        response = self.client.post(url, {"action": "suspend"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.client_user.refresh_from_db()
        self.assertFalse(self.client_user.is_active)

        # Unsuspend
        response = self.client.post(url, {"action": "unsuspend"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.client_user.refresh_from_db()
        self.assertTrue(self.client_user.is_active)

    def test_technician_services_crud(self):
        self.client.force_authenticate(user=self.tech_user)
        url = reverse("technician_services")
        response = self.client.post(url, {
            "title": "Electrical Repair",
            "category": self.category.id,
            "description": "General electrical repairs",
            "service_type": "onsite",
            "coverage_area": "Lahore",
            "pricing_model": "fixed",
            "pricing_min": "5000",
            "pricing_max": "10000",
        }, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        service_id = response.data["id"]

        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        detail_url = reverse("technician_service_detail", kwargs={"service_id": service_id})
        response = self.client.patch(detail_url, {"title": "Updated Repair"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["title"], "Updated Repair")
