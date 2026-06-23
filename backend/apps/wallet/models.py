from django.db import models
from django.conf import settings


class Wallet(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='wallet')
    available_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    pending_escrow = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_earnings = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_withdrawn = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    currency = models.CharField(max_length=10, default='XOF')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'wallet_wallet'

    def __str__(self):
        return f'Wallet - {self.user.email}'

    def can_withdraw(self, amount):
        return self.available_balance >= amount


class Transaction(models.Model):
    TYPE_CHOICES = (
        ('credit', 'Credit'),
        ('debit', 'Debit'),
        ('pending', 'Pending'),
    )
    CATEGORY_CHOICES = (
        ('earnings', 'Earnings'),
        ('withdrawal', 'Withdrawal'),
        ('escrow_hold', 'Escrow Hold'),
        ('escrow_release', 'Escrow Release'),
        ('refund', 'Refund'),
    )
    STATUS_CHOICES = (
        ('completed', 'Completed'),
        ('pending', 'Pending'),
        ('failed', 'Failed'),
    )

    id = models.AutoField(primary_key=True)
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE, related_name='transactions')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    reference = models.ForeignKey('tasks.Task', on_delete=models.SET_NULL, null=True, blank=True, related_name='transactions')
    description = models.CharField(max_length=255, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='completed')
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'wallet_transaction'
        indexes = [
            models.Index(fields=['wallet']),
            models.Index(fields=['type']),
            models.Index(fields=['category']),
            models.Index(fields=['status']),
            models.Index(fields=['-created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.type} {self.amount} - {self.wallet.user.email}'
