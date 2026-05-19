"""URL patterns for location app — with real-time tracking."""
from django.urls import path
from .views import (
    LocationUpdateView, LocationHistoryView,
    LatestLocationView, BulkLocationUpdateView,
    RouteView, LiveTrackingSessionView, PublicTrackingView,
)

urlpatterns = [
    path('update/', LocationUpdateView.as_view(), name='location-update'),
    path('history/', LocationHistoryView.as_view(), name='location-history'),
    path('latest/', LatestLocationView.as_view(), name='location-latest'),
    path('bulk/', BulkLocationUpdateView.as_view(), name='location-bulk'),
    path('route/', RouteView.as_view(), name='location-route'),
    path('tracking/', LiveTrackingSessionView.as_view(), name='live-tracking'),
    path('track/<str:share_token>/', PublicTrackingView.as_view(), name='public-tracking'),
]
