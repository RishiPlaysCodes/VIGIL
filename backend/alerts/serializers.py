"""Serializers for alerts app — Production-grade."""
from rest_framework import serializers
from .models import Alert, AlertEvidence, AlertLocationTrail


class AlertLocationTrailSerializer(serializers.ModelSerializer):
    """Serializer for location trail points."""
    class Meta:
        model = AlertLocationTrail
        fields = [
            'id', 'latitude', 'longitude', 'accuracy', 'speed',
            'bearing', 'altitude', 'address', 'battery_level', 'timestamp'
        ]
        read_only_fields = ['id']


class AlertEvidenceSerializer(serializers.ModelSerializer):
    """Serializer for alert evidence (photos, videos, etc.)."""
    class Meta:
        model = AlertEvidence
        fields = [
            'id', 'evidence_type', 'file', 'thumbnail',
            'metadata', 'captured_at', 'uploaded_at'
        ]
        read_only_fields = ['id', 'uploaded_at']


class AlertSerializer(serializers.ModelSerializer):
    """Full alert serializer with evidence and trail."""
    evidence = AlertEvidenceSerializer(many=True, read_only=True)
    location_trail_count = serializers.SerializerMethodField()
    duration_seconds = serializers.SerializerMethodField()

    class Meta:
        model = Alert
        fields = [
            'id', 'status', 'trigger_type',
            'threat_confidence', 'extraction_score', 'movement_context', 'ai_reason',
            'latitude', 'longitude', 'address', 'speed_at_trigger',
            'sensor_snapshot', 'proximity_value', 'light_value',
            'accel_magnitude', 'gyro_magnitude', 'jerk_value',
            'face_verification_result', 'face_confidence', 'auth_method_used',
            'emergency_activated', 'emergency_activated_at', 'emergency_deactivated_at',
            'photos_captured', 'photos_uploaded',
            'sms_sent', 'email_sent', 'sms_retry_count', 'contacts_notified',
            'triggered_at', 'acknowledged_at', 'resolved_at',
            'notes', 'evidence', 'location_trail_count', 'duration_seconds',
        ]
        read_only_fields = ['id', 'triggered_at']

    def get_location_trail_count(self, obj):
        return obj.location_trail.count()

    def get_duration_seconds(self, obj):
        if obj.resolved_at and obj.triggered_at:
            return int((obj.resolved_at - obj.triggered_at).total_seconds())
        return None


class AlertCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating alerts with AI data."""
    class Meta:
        model = Alert
        fields = [
            'trigger_type', 'threat_confidence', 'extraction_score',
            'movement_context', 'ai_reason',
            'latitude', 'longitude', 'address', 'speed_at_trigger',
            'sensor_snapshot', 'proximity_value', 'light_value',
            'accel_magnitude', 'gyro_magnitude', 'jerk_value',
        ]

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
