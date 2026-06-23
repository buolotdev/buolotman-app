from django.urls import path
from . import views

urlpatterns = [
    path('', views.task_list, name='task_list'),
    path('create/', views.task_create, name='task_create'),
    path('my/', views.my_tasks, name='my_tasks'),
    path('categories/', views.category_list, name='category_list'),
    path('categories/<int:category_id>/', views.category_detail, name='category_detail'),
    path('skills/', views.skill_list, name='skill_list'),
    path('<int:task_id>/', views.task_detail, name='task_detail'),
    path('<int:task_id>/publish/', views.task_publish, name='task_publish'),
    path('<int:task_id>/complete/', views.task_complete, name='task_complete'),
    path('<int:task_id>/cancel/', views.task_cancel, name='task_cancel'),
    path('<int:task_id>/bids/', views.task_bids, name='task_bids'),
    path('<int:task_id>/questions/', views.task_questions, name='task_questions'),
    path('bids/<int:bid_id>/', views.bid_detail, name='bid_detail'),
    path('bids/<int:bid_id>/withdraw/', views.bid_withdraw, name='bid_withdraw'),
    path('bids/my/', views.my_bids, name='my_bids'),
]
