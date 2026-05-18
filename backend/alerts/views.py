"""Views for alerts app — Production-grade with evidence management."""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from django.utils import timezone

from .models import Alert, AlertEvidence, AlertLocationTrail
from .serializers import (
    AlertSerializer, AlertCreateSerializer,
    AlertEvidenceSerializer, AlertLocationTrailSerializer,
)
from .services import send_alert_notifications


class AlertCreateThrottle(ScopedRateThrottle):
    scope = 'alert_create'


class EvidenceUploadThrottle(ScopedRateThrottle):
    scope = 'evidence_upload'


class AlertViewSet(viewsets.ModelViewSet):
    """CRUD + action endpoints for alerts with evidence and tracking."""
    throttle_classes = [AlertCreateThrottle]

    def get_serializer_class(self):
        if self.action == 'create':
            return AlertCreateSerializer
        return AlertSerializer

    def get_queryset(self):
        return Alert.objects.filter(user=self.request.user).prefetch_related(
            'evidence', 'location_trail'
        )

    def perform_create(self, serializer):
        alert = serializer.save(user=self.request.user)
        # Update user stats
        self.request.user.total_alerts += 1
        self.request.user.save(update_fields=['total_alerts'])
        # Trigger notifications in background
        send_alert_notifications(alert)

    @action(detail=True, methods=['post'])
    def acknowledge(self, request, pk=None):
        """Owner verified identity — cancel the alert."""
        alert = self.get_object()
        auth_method = request.data.get('auth_method', 'unknown')
        alert.status = 'auth_cancelled'
        alert.auth_method_used = auth_method
        alert.acknowledged_at = timezone.now()
        alert.save()
        return Response({
            'status': 'Alert cancelled by verified owner',
            'auth_method': auth_method,
        })

    @action(detail=True, methods=['post'])
    def face_verified(self, request, pk=None):
        """Face auto-verification succeeded — silent cancel."""
        alert = self.get_object()
        confidence = request.data.get('confidence', 0)
        alert.status = 'face_verified'
        alert.face_verification_result = 'owner_recognized'
        alert.face_confidence = confidence
        alert.acknowledged_at = timezone.now()
        alert.save()
        return Response({'status': 'Auto-cancelled by face verification'})

    @action(detail=True, methods=['post'])
    def activate_emergency(self, request, pk=None):
        """Escalate to full emergency protocol."""
        alert = self.get_object()
        alert.status = 'emergency_active'
        alert.emergency_activated = True
        alert.emergency_activated_at = timezone.now()
        alert.save()
        return Response({'status': 'Emergency protocol activated'})

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Mark alert as resolved."""
        alert = self.get_object()
        alert.status = 'resolved'
        alert.resolved_at = timezone.now()
        if alert.emergency_activated and not alert.emergency_deactivated_at:
            alert.emergency_deactivated_at = timezone.now()
        alert.save()
        return Response({'status': 'Alert resolved'})

    @action(detail=True, methods=['post'])
    def mark_false_alarm(self, request, pk=None):
        """Mark as false alarm (helps AI learn)."""
        alert = self.get_object()
        alert.status = 'false_alarm'
        alert.acknowledged_at = timezone.now()
        alert.notes = request.data.get('reason', 'Marked as false alarm by user')
        alert.save()
        # Update user false alarm count for AI learning
        self.request.user.false_alarms += 1
        self.request.user.save(update_fields=['false_alarms'])
        return Response({'status': 'Marked as false alarm'})

    @action(detail=True, methods=['post'], throttle_classes=[EvidenceUploadThrottle])
    def upload_evidence(self, request, pk=None):
        """Upload evidence (photo/video/audio) for the alert."""
        alert = self.get_object()
        serializer = AlertEvidenceSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        evidence = serializer.save(alert=alert)
        # Update photo count
        alert.photos_uploaded = alert.evidence.filter(evidence_type='photo').count()
        alert.save(update_fields=['photos_uploaded'])
        return Response(
            AlertEvidenceSerializer(evidence).data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['post'])
    def add_location_trail(self, request, pk=None):
        """Add a location point to the alert's tracking trail."""
        alert = self.get_object()
        serializer = AlertLocationTrailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(alert=alert)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'])
    def trail(self, request, pk=None):
        """Get complete location trail for an alert."""
        alert = self.get_object()
        trail = alert.location_trail.all()[:500]
        serializer = AlertLocationTrailSerializer(trail, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def evidence_list(self, request, pk=None):
        """Get all evidence for an alert."""
        alert = self.get_object()
        evidence = alert.evidence.all()
        serializer = AlertEvidenceSerializer(evidence, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get currently active alerts."""
        alerts = self.get_queryset().filter(
            status__in=['triggered', 'emergency_active']
        )
        serializer = AlertSerializer(alerts, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def history(self, request):
        """Get alert history with pagination."""
        alerts = self.get_queryset().exclude(
            status__in=['triggered', 'emergency_active']
        )
        page = self.paginate_queryset(alerts)
        if page is not None:
            serializer = AlertSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = AlertSerializer(alerts, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Get alert statistics for the user."""
        user = request.user
        alerts = Alert.objects.filter(user=user)
        now = timezone.now()
        from datetime import timedelta

        return Response({
            'total': alerts.count(),
            'this_week': alerts.filter(
                triggered_at__gte=now - timedelta(days=7)
            ).count(),
            'this_month': alerts.filter(
                triggered_at__gte=now - timedelta(days=30)
            ).count(),
            'false_alarms': alerts.filter(status='false_alarm').count(),
            'face_auto_cancelled': alerts.filter(status='face_verified').count(),
            'emergency_triggered': alerts.filter(emergency_activated=True).count(),
            'avg_threat_confidence': alerts.aggregate(
                avg=models.Avg('threat_confidence')
            )['avg'] or 0,
        })
