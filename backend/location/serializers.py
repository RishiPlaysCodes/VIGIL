"""Serializers for location app."""
from rest_framework import serializers
from .models import UserLocation


class UserLocationSerializer(serializers.ModelSerializer):
    """Serializer for user location."""
    class Meta:
        model = UserLocation
        fields = [
            'id', 'latitude', 'longitude', 'accuracy', 'altitude',
            'speed', 'battery_level', 'is_moving', 'timestamp'
        ]
        read_only_fields = ['id', 'timestamp']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
