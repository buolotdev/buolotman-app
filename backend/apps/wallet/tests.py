from django.urls import reverse
from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase
from apps.tasks.models import Task, Bid, Category
from apps.wallet.models import Wallet, Transaction

User = get_user_model()

class WalletAPITests(APITestCase):
    def setUp(self):
        # Create users
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

        # Create wallets
        self.client_wallet, _ = Wallet.objects.get_or_create(user=self.client_user)
        self.tech_wallet, _ = Wallet.objects.get_or_create(user=self.tech_user)

        # Pre-fund client wallet available balance to test withdrawals/escrow deposits
        self.client_wallet.available_balance = 50000.00
        self.client_wallet.save()

        # Create category & task
        self.category = Category.objects.create(name="Plumbing", slug="plumbing")
        self.task = Task.objects.create(
            title="Leaky Sink",
            description="Leaking sink",
            category=self.category,
            client=self.client_user,
            status="open",
            budget_min=10000,
            budget_max=20000
        )
        # Bid on task
        self.bid = Bid.objects.create(
            task=self.task,
            technician=self.tech_user,
            amount=15000.00,
            amount_type="fixed",
            message="I can fix it"
        )

    def test_wallet_detail(self):
        self.client.force_authenticate(user=self.client_user)
        url = reverse("wallet_detail")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(float(response.data["available_balance"]), 50000.00)

    def test_withdraw_funds(self):
        self.client.force_authenticate(user=self.client_user)
        url = reverse("withdraw_funds")
        data = {
            "amount": 20000.00,
            "account_details": {"bank": "Orange Money", "phone": "+12345678"}
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.client_wallet.refresh_from_db()
        self.assertEqual(float(self.client_wallet.available_balance), 30000.00)

    def test_deposit_and_release_escrow(self):
        self.client.force_authenticate(user=self.client_user)
        
        # Deposit escrow for task
        deposit_url = reverse("deposit_escrow")
        data = {
            "task_id": self.task.id,
            "bid_id": self.bid.id,
            "amount": 15000.00
        }
        response = self.client.post(deposit_url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        self.client_wallet.refresh_from_db()
        self.assertEqual(float(self.client_wallet.pending_escrow), 15000.00)
        self.task.refresh_from_db()
        self.assertEqual(self.task.status, "in_progress")
        self.assertEqual(self.task.assigned_to, self.tech_user)

        # Complete task (must be completed to release escrow)
        self.task.status = "completed"
        self.task.save()

        # Release escrow
        release_url = reverse("release_escrow", kwargs={"task_id": self.task.id})
        response = self.client.post(release_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.client_wallet.refresh_from_db()
        self.tech_wallet.refresh_from_db()
        self.assertEqual(float(self.client_wallet.pending_escrow), 0.00)
        self.assertEqual(float(self.tech_wallet.available_balance), 15000.00)
