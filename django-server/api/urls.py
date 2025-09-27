from django.urls import path
from . import views

urlpatterns = [
    path('info/', views.server_info, name='server_info'),
    path('health/', views.health_check, name='health_check'),
    path('echo/', views.echo, name='echo'),
]