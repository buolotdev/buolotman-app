from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    path('login/', views.CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('otp/request/', views.request_phone_otp, name='request_phone_otp'),
    path('otp/verify/', views.verify_phone_otp, name='verify_phone_otp'),
    path('register/client/', views.register_client, name='register_client'),
    path('register/technician/', views.register_technician, name='register_technician'),
    path('register/company/', views.register_company, name='register_company'),
    path('me/', views.me, name='me'),
    path('users/', views.list_users, name='list_users'),
    path('users/<int:user_id>/', views.user_public_profile, name='user_public_profile'),
    path('portfolio/', views.portfolio_items, name='portfolio_items'),
    path('portfolio/<int:item_id>/', views.portfolio_item_detail, name='portfolio_item_detail'),
    path('saved-pros/', views.saved_professionals, name='saved_professionals'),
    path('saved-pros/<int:professional_id>/', views.saved_professional_detail, name='saved_professional_detail'),
    path('technician-services/', views.technician_services, name='technician_services'),
    path('technician-services/<int:service_id>/', views.technician_service_detail, name='technician_service_detail'),
    path('admin/users/', views.admin_list_users, name='admin_list_users'),
    path('admin/users/<int:user_id>/verify/', views.admin_verify_user, name='admin_verify_user'),
    path('admin/users/<int:user_id>/suspend/', views.admin_suspend_user, name='admin_suspend_user'),
    path('admin/tasks/', views.admin_list_tasks, name='admin_list_tasks'),
]
