"""URL patterns for location app."""
from django.urls import path
from .views import (
    LocationUpdateView, LocationHistoryView,
    LatestLocationView, BulkLocationUpdateView
)

urlpatterns = [
    path('update/', LocationUpdateView.as_view(), name='location-update'),
    path('history/', LocationHistoryView.as_view(), name='location-history'),
    path('latest/', LatestLocationView.as_view(), name='location-latest'),
    path('bulk/', BulkLocationUpdateView.as_view(), name='location-bulk'),
]
