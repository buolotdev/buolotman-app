from django.urls import path
from . import views

urlpatterns = [
    path("avatar/", views.upload_avatar, name="upload_avatar"),
    path("portfolio/", views.upload_portfolio_image, name="upload_portfolio_image"),
    path("task/<int:task_id>/", views.upload_task_attachment, name="upload_task_attachment"),
    path("delete/<path:key>/", views.delete_upload, name="delete_upload"),
]
