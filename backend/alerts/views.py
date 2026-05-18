"""Views for alerts app."""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone

from .models import Alert, LocationHistory
from .serializers import (
    AlertSerializer, AlertCreateSerializer,
    LocationHistorySerializer, IntruderPhotoSerializer
)
from .services import send_alert_notifications


class AlertViewSet(viewsets.ModelViewSet):
    """CRUD + action endpoints for alerts."""
    
    def get_serializer_class(self):
        if self.action == 'create':
            return AlertCreateSerializer
        return AlertSerializer

    def get_queryset(self):
        return Alert.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        alert = serializer.save(user=self.request.user)
        # Trigger notifications to emergency contacts
        send_alert_notifications(alert)

    @action(detail=True, methods=['post'])
    def acknowledge(self, request, pk=None):
        """Owner acknowledges / cancels the alert."""
        alert = self.get_object()
        alert.status = 'cancelled'
        alert.acknowledged_at = timezone.now()
        alert.save()
        return Response({'status': 'Alert cancelled by owner'})

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Mark alert as resolved."""
        alert = self.get_object()
        alert.status = 'resolved'
        alert.resolved_at = timezone.now()
        alert.save()
        return Response({'status': 'Alert resolved'})

    @action(detail=True, methods=['post'])
    def upload_photo(self, request, pk=None):
        """Upload intruder photo for the alert."""
        alert = self.get_object()
        serializer = IntruderPhotoSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        alert.intruder_photo = serializer.validated_data['photo']
        alert.save()
        return Response({'status': 'Photo uploaded', 'url': alert.intruder_photo.url})

    @action(detail=True, methods=['post'])
    def add_location(self, request, pk=None):
        """Add a location point during active alert tracking."""
        alert = self.get_object()
        serializer = LocationHistorySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(alert=alert)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get currently active (triggered) alerts."""
        alerts = self.get_queryset().filter(status='triggered')
        serializer = AlertSerializer(alerts, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def history(self, request):
        """Get alert history."""
        alerts = self.get_queryset().exclude(status='triggered')
        serializer = AlertSerializer(alerts, many=True)
        return Response(serializer.data)
