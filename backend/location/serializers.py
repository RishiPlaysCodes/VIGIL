"""Serializers for location app."""
from rest_framework import serializers
from .models import UserLocation, LiveTrackingSession


class UserLocationSerializer(serializers.ModelSerializer):
    """Serializer for user location with full tracking data."""
    google_maps_link = serializers.ReadOnlyField()
    speed_kmh = serializers.ReadOnlyField()

    class Meta:
        model = UserLocation
        fields = [
            'id', 'latitude', 'longitude', 'accuracy', 'altitude',
            'speed', 'bearing', 'battery_level', 'is_moving',
            'address', 'speed_classification', 'tracking_mode',
            'google_maps_link', 'speed_kmh', 'timestamp',
        ]
        read_only_fields = ['id', 'timestamp', 'google_maps_link', 'speed_kmh']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class LocationRouteSerializer(serializers.Serializer):
    """Serializer for route polyline data."""
    lat = serializers.FloatField()
    lng = serializers.FloatField()
    speed = serializers.FloatField(required=False)
    time = serializers.DateTimeField(required=False)


class LiveTrackingSessionSerializer(serializers.ModelSerializer):
    """Serializer for live tracking sessions."""
    live_link = serializers.ReadOnlyField()

    class Meta:
        model = LiveTrackingSession
        fields = [
            'id', 'share_token', 'is_active', 'started_at',
            'ended_at', 'triggered_by', 'shared_with', 'live_link',
        ]
        read_only_fields = ['id', 'share_token', 'started_at', 'live_link']
