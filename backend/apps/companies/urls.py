from django.urls import path
from . import views

urlpatterns = [
    path('', views.list_companies, name='list_companies'),
    path('profile/', views.company_profile, name='company_profile'),
    path('projects/', views.company_projects_list_create, name='company_projects'),
    path('certifications/', views.company_certifications_list_create, name='company_certifications'),
    path('services/', views.company_services, name='company_services'),
    path('services/<int:service_id>/', views.delete_company_service, name='delete_company_service'),
    path('<int:company_id>/', views.company_public_profile, name='company_public_profile'),
    path('<int:company_id>/reviews/', views.add_company_review, name='add_company_review'),
]
