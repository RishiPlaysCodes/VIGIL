"""Serializers for contacts app."""
from rest_framework import serializers
from .models import EmergencyContact


class EmergencyContactSerializer(serializers.ModelSerializer):
    """Serializer for emergency contacts."""
    class Meta:
        model = EmergencyContact
        fields = [
            'id', 'name', 'phone_number', 'email', 'relationship',
            'is_primary', 'notify_by_sms', 'notify_by_email',
            'notify_by_call', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
