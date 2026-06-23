from rest_framework import serializers
from .models import Wallet, Transaction


class WalletSerializer(serializers.ModelSerializer):
    class Meta:
        model = Wallet
        fields = ['id', 'available_balance', 'pending_escrow', 'total_earnings', 'total_withdrawn', 'currency']
        read_only_fields = ['id', 'total_earnings', 'total_withdrawn']


class TransactionSerializer(serializers.ModelSerializer):
    task_title = serializers.CharField(source='reference.title', read_only=True, default='')

    class Meta:
        model = Transaction
        fields = ['id', 'amount', 'type', 'category', 'task_title', 'description', 'status', 'metadata', 'created_at']
        read_only_fields = ['id', 'created_at']


class WithdrawSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    method = serializers.CharField(max_length=50, required=False, default='bank_transfer')
    account_details = serializers.JSONField(required=False, default=dict)

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Amount must be positive.")
        return value
