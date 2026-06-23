from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db import transaction as db_transaction

from apps.governance.services import create_notification, create_audit_log

from .models import Wallet, Transaction
from .serializers import WalletSerializer, TransactionSerializer, WithdrawSerializer


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def wallet_detail(request):
    wallet, _ = Wallet.objects.get_or_create(user=request.user)
    serializer = WalletSerializer(wallet)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def withdraw_funds(request):
    wallet, _ = Wallet.objects.get_or_create(user=request.user)
    serializer = WithdrawSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    amount = serializer.validated_data['amount']
    if not wallet.can_withdraw(amount):
        return Response({"error": "Insufficient balance"}, status=status.HTTP_400_BAD_REQUEST)

    with db_transaction.atomic():
        wallet.available_balance -= amount
        wallet.total_withdrawn += amount
        wallet.save(update_fields=['available_balance', 'total_withdrawn'])

        Transaction.objects.create(
            wallet=wallet,
            amount=amount,
            type='debit',
            category='withdrawal',
            description=f'Withdrawal of {amount} {wallet.currency}',
            status='pending',
            metadata=serializer.validated_data.get('account_details', {}),
        )
        create_audit_log(
            actor=request.user,
            action="withdrawal_requested",
            entity_type="wallet",
            entity_id=wallet.id,
            summary=f"Withdrawal of {amount} {wallet.currency}",
            metadata={"amount": str(amount), "currency": wallet.currency},
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        create_notification(
            user=request.user,
            category="payment",
            title="Withdrawal initiated",
            body=f"Your withdrawal request for {amount} {wallet.currency} has been submitted.",
            link="/dashboard/technician/wallet",
            metadata={"amount": str(amount), "currency": wallet.currency},
        )

    return Response({"message": "Withdrawal initiated", "available_balance": str(wallet.available_balance)})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def transaction_list(request):
    wallet, _ = Wallet.objects.get_or_create(user=request.user)
    transactions = wallet.transactions.all()

    type_filter = request.query_params.get('type')
    if type_filter:
        transactions = transactions.filter(type=type_filter)

    category_filter = request.query_params.get('category')
    if category_filter:
        transactions = transactions.filter(category=category_filter)

    page = int(request.query_params.get('page', 1))
    limit = int(request.query_params.get('limit', 20))
    start = (page - 1) * limit
    end = start + limit
    total = transactions.count()

    serializer = TransactionSerializer(transactions[start:end], many=True)
    return Response({
        'results': serializer.data,
        'total': total,
        'page': page,
        'limit': limit,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_transaction_list(request):
    if getattr(request.user, 'role', None) != 'ADMIN':
        return Response({"error": "Admin only"}, status=status.HTTP_403_FORBIDDEN)

    transactions = Transaction.objects.select_related('wallet__user').all().order_by('-created_at')

    type_filter = request.query_params.get('type')
    if type_filter:
        transactions = transactions.filter(type=type_filter)

    page = int(request.query_params.get('page', 1))
    limit = int(request.query_params.get('limit', 50))
    start = (page - 1) * limit
    end = start + limit
    total = transactions.count()
    total_in_escrow = sum(w.available_balance for w in Wallet.objects.all()) or 0
    pending_payouts = Transaction.objects.filter(type='withdrawal', status='pending').count()

    data = []
    for tx in transactions[start:end]:
        data.append({
            'id': tx.id,
            'type': tx.type,
            'amount': str(tx.amount),
            'status': tx.status,
            'description': tx.description or '',
            'user_name': tx.wallet.user.get_full_name() or tx.wallet.user.email,
            'user_email': tx.wallet.user.email,
            'created_at': tx.created_at,
        })

    return Response({
        'results': data,
        'total': total,
        'page': page,
        'limit': limit,
        'total_in_escrow': str(total_in_escrow),
        'pending_payouts': pending_payouts,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deposit_escrow(request):
    from apps.tasks.models import Task

    task_id = request.data.get('task_id')
    bid_id = request.data.get('bid_id')
    amount = request.data.get('amount')

    if not task_id or not amount:
        return Response({"error": "task_id and amount are required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        task = Task.objects.get(id=task_id)
    except Task.DoesNotExist:
        return Response({"error": "Task not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.user != task.client:
        return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)

    from decimal import Decimal
    amount = Decimal(str(amount))

    wallet, _ = Wallet.objects.get_or_create(user=request.user)
    bid = None
    if bid_id:
        from apps.tasks.models import Bid
        try:
            bid = Bid.objects.get(id=bid_id)
        except Bid.DoesNotExist:
            return Response({"error": "Bid not found"}, status=status.HTTP_404_NOT_FOUND)

    with db_transaction.atomic():
        wallet.pending_escrow += amount
        wallet.save(update_fields=['pending_escrow', 'updated_at'])

        Transaction.objects.create(
            wallet=wallet,
            amount=amount,
            type='pending',
            category='escrow_hold',
            reference=task,
            description=f"Escrow held for task: {task.title}",
            status='completed',
            metadata={'bid_id': bid_id} if bid_id else {},
        )
        create_audit_log(
            actor=request.user,
            action="escrow_deposited",
            entity_type="wallet",
            entity_id=wallet.id,
            summary=task.title,
            metadata={"task_id": task.id, "bid_id": bid_id, "amount": str(amount)},
            ip_address=request.META.get("REMOTE_ADDR"),
        )

        if bid:
            bid.status = 'accepted'
            from django.utils import timezone
            bid.accepted_at = timezone.now()
            bid.save(update_fields=['status', 'accepted_at'])
            task.status = 'in_progress'
            task.assigned_to = bid.technician
            task.save(update_fields=['status', 'assigned_to'])
            create_notification(
                user=bid.technician,
                category="payment",
                title=f"Escrow funded for {task.title}",
                body="The client has funded the task and it is now active.",
                link=f"/dashboard/technician/tasks/{task.id}",
                metadata={"task_id": task.id, "bid_id": bid.id},
            )
            create_notification(
                user=request.user,
                category="payment",
                title=f"Escrow deposited for {task.title}",
                body="Funds are now held in escrow for your task.",
                link=f"/dashboard/client/tasks/{task.id}",
                metadata={"task_id": task.id, "bid_id": bid.id},
            )

    return Response({
        "message": "Escrow deposited",
        "pending_escrow": str(wallet.pending_escrow),
        "task_status": task.status,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def release_escrow(request, task_id):
    from apps.tasks.models import Task
    try:
        task = Task.objects.get(id=task_id)
    except Task.DoesNotExist:
        return Response({"error": "Task not found"}, status=status.HTTP_404_NOT_FOUND)

    client_wallet, _ = Wallet.objects.get_or_create(user=task.client)
    try:
        pending_tx = Transaction.objects.get(
            wallet=client_wallet,
            reference=task,
            category='escrow_hold',
        )
    except Transaction.DoesNotExist:
        return Response({"error": "No escrow found for this task. Deposit escrow before releasing."}, status=status.HTTP_400_BAD_REQUEST)

    if task.status != 'completed':
        return Response({"error": "Task must be completed first"}, status=status.HTTP_400_BAD_REQUEST)

    amount = pending_tx.amount

    with db_transaction.atomic():
        client_wallet.pending_escrow -= amount
        client_wallet.save(update_fields=['pending_escrow', 'updated_at'])

        if task.assigned_to:
            tech_wallet, _ = Wallet.objects.get_or_create(user=task.assigned_to)
            tech_wallet.available_balance += amount
            tech_wallet.total_earnings += amount
            tech_wallet.save(update_fields=['available_balance', 'total_earnings', 'updated_at'])
            Transaction.objects.create(
                wallet=tech_wallet,
                amount=amount,
                type='credit',
                category='earnings',
                reference=task,
                description=f"Payment received for: {task.title}",
                status='completed',
            )

        pending_tx.category = 'escrow_release'
        pending_tx.description = f"Escrow released for task {task_id}"
        pending_tx.save(update_fields=['category', 'description'])
        create_audit_log(
            actor=request.user,
            action="escrow_released",
            entity_type="wallet",
            entity_id=client_wallet.id,
            summary=task.title,
            metadata={"task_id": task.id, "amount": str(amount)},
            ip_address=request.META.get("REMOTE_ADDR"),
        )
        if task.client:
            create_notification(
                user=task.client,
                category="payment",
                title=f"Escrow released for {task.title}",
                body="The escrow funds have been released.",
                link=f"/dashboard/client/tasks/{task.id}",
                metadata={"task_id": task.id, "amount": str(amount)},
            )
        if task.assigned_to:
            create_notification(
                user=task.assigned_to,
                category="payment",
                title=f"Payment received for {task.title}",
                body="Escrow release completed and your balance was updated.",
                link="/dashboard/technician/wallet",
                metadata={"task_id": task.id, "amount": str(amount)},
            )

    return Response({"message": "Escrow released", "amount": str(amount)})
