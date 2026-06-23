from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from apps.companies.models import CompanyProfile, CompanyProject, CompanyService, CompanyCertification, CompanyReview

User = get_user_model()

class CompaniesAPITests(APITestCase):
    def setUp(self):
        self.company_user = User.objects.create_user(
            username="company@test.com",
            email="company@test.com",
            password="password123",
            role="COMPANY",
            first_name="Acme Corp"
        )
        self.client_user = User.objects.create_user(
            username="client@test.com",
            email="client@test.com",
            password="password123",
            role="CLIENT",
            first_name="Jane",
            last_name="Doe"
        )
        # Verify if profile was automatically created during register
        self.company_profile, _ = CompanyProfile.objects.get_or_create(
            user=self.company_user,
            defaults={"company_name": "Acme Corp"}
        )

    def test_company_profile(self):
        self.client.force_authenticate(user=self.company_user)
        url = reverse("company_profile")
        
        # GET profile
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["company_name"], "Acme Corp")

        # PATCH profile
        response = self.client.partial_update = self.client.patch(url, {"about": "Leading IT Services Provider"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["about"], "Leading IT Services Provider")

    def test_company_services(self):
        self.client.force_authenticate(user=self.company_user)
        url = reverse("company_services")

        # POST service
        response = self.client.post(url, {"title": "Software Development", "description": "Custom Next.js & Django development"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        service_id = response.data["id"]

        # GET services
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        # DELETE service
        delete_url = reverse("delete_company_service", kwargs={"service_id": service_id})
        response = self.client.delete(delete_url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

    def test_company_projects_list_create(self):
        self.client.force_authenticate(user=self.company_user)
        url = reverse("company_projects")

        # POST project
        data = {
            "title": "E-Commerce App Integration",
            "status": "active",
            "client_name": "Local Retailer",
            "budget": 5000000.00,
            "timeline": "3 months",
            "milestones_total": 5,
            "milestones_completed": 1,
            "payment_status": "funded",
            "progress": 20
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        # GET projects
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_add_company_review(self):
        self.client.force_authenticate(user=self.client_user)
        url = reverse("add_company_review", kwargs={"company_id": self.company_profile.id})
        
        review_data = {
            "rating": 5,
            "text": "Excellent company! Highly professional devs.",
            "service": "App Development"
        }
        response = self.client.post(url, review_data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        # Verify average rating updated
        self.company_profile.refresh_from_db()
        self.assertEqual(float(self.company_profile.average_rating), 5.00)
        self.assertEqual(self.company_profile.review_count, 1)
