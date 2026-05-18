"""Serializers for alerts app."""
from rest_framework import serializers
from .models import Alert, LocationHistory


class LocationHistorySerializer(serializers.ModelSerializer):
    """Serializer for location history."""
    class Meta:
        model = LocationHistory
        fields = ['id', 'latitude', 'longitude', 'accuracy', 'timestamp']
        read_only_fields = ['id', 'timestamp']


class AlertSerializer(serializers.ModelSerializer):
    """Serializer for alerts."""
    location_history = LocationHistorySerializer(many=True, read_only=True)

    class Meta:
        model = Alert
        fields = [
            'id', 'status', 'trigger_type', 'latitude', 'longitude',
            'address', 'intruder_photo', 'proximity_value', 'light_value',
            'accelerometer_data', 'sms_sent', 'email_sent',
            'contacts_notified', 'triggered_at', 'acknowledged_at',
            'resolved_at', 'notes', 'location_history'
        ]
        read_only_fields = ['id', 'triggered_at']


class AlertCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating alerts."""
    class Meta:
        model = Alert
        fields = [
            'trigger_type', 'latitude', 'longitude', 'address',
            'proximity_value', 'light_value', 'accelerometer_data'
        ]

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class IntruderPhotoSerializer(serializers.Serializer):
    """Serializer for uploading intruder photo."""
    photo = serializers.ImageField()
