"""URL patterns for contacts app."""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EmergencyContactViewSet

router = DefaultRouter()
router.register('', EmergencyContactViewSet, basename='emergency-contacts')

urlpatterns = [
    path('', include(router.urls)),
]
