# notifications/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('<str:firebase_uid>/', views.user_notifications, name='user_notifications'),
    path('<str:firebase_uid>/<str:notification_id>/read/', views.mark_as_read, name='mark_as_read'),
    path('<str:firebase_uid>/mark-all-read/', views.mark_all_as_read, name='mark_all_as_read'),
    path('<str:firebase_uid>/<str:notification_id>/', views.delete_notification, name='delete_notification'),
]