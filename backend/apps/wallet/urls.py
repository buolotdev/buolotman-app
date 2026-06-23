from django.urls import path
from . import views

urlpatterns = [
    path('', views.wallet_detail, name='wallet_detail'),
    path('withdraw/', views.withdraw_funds, name='withdraw_funds'),
    path('deposit/', views.deposit_escrow, name='deposit_escrow'),
    path('transactions/', views.transaction_list, name='transaction_list'),
    path('admin/transactions/', views.admin_transaction_list, name='admin_transaction_list'),
    path('release-escrow/<int:task_id>/', views.release_escrow, name='release_escrow'),
]
