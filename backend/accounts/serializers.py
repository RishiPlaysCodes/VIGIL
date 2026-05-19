"""Serializers for accounts app — Production-grade with AI features."""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    """Serializer for user registration."""
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'phone_number', 'password', 'password_confirm']

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password": "Passwords do not match."})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        user = User.objects.create_user(**validated_data)
        return user


class LoginSerializer(serializers.Serializer):
    """Serializer for user login."""
    username = serializers.CharField()
    password = serializers.CharField()


class UserProfileSerializer(serializers.ModelSerializer):
    """Full user profile serializer."""
    protection_score = serializers.ReadOnlyField()

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'phone_number', 'profile_image',
            'safety_avatar', 'pocket_mode_enabled', 'grace_period_seconds',
            'high_security_mode', 'battery_saver_mode',
            'ai_sensitivity', 'extraction_confidence_threshold', 'false_positive_learning',
            'schedule_enabled', 'schedule_start_time', 'schedule_end_time', 'schedule_days',
            'location_sharing_enabled', 'continuous_location_sync', 'tracking_mode',
            'face_enrolled', 'fingerprint_enabled', 'voice_password_enabled',
            'pin_enabled', 'required_auth_methods',
            'custom_ringtone', 'lock_screen_image', 'guardian_character',
            'safe_zones', 'trusted_devices',
            'total_alerts', 'false_alarms', 'days_protected', 'protection_score',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at', 'total_alerts', 'false_alarms', 'protection_score']


class UserSettingsSerializer(serializers.ModelSerializer):
    """Serializer for updating user settings."""
    class Meta:
        model = User
        fields = [
            'pocket_mode_enabled', 'grace_period_seconds',
            'high_security_mode', 'battery_saver_mode',
            'ai_sensitivity', 'extraction_confidence_threshold', 'false_positive_learning',
            'schedule_enabled', 'schedule_start_time', 'schedule_end_time', 'schedule_days',
            'location_sharing_enabled', 'continuous_location_sync', 'tracking_mode',
            'face_enrolled', 'fingerprint_enabled', 'voice_password_enabled',
            'pin_enabled', 'required_auth_methods',
            'custom_ringtone', 'safety_avatar', 'guardian_character',
            'safe_zones', 'trusted_devices',
        ]


class SafeZoneSerializer(serializers.Serializer):
    """Serializer for safe zone management."""
    id = serializers.CharField(required=False)
    name = serializers.CharField(max_length=100)
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    radius_meters = serializers.FloatField(default=100)
    type = serializers.ChoiceField(
        choices=['home', 'work', 'school', 'gym', 'custom'],
        default='custom'
    )


class TrustedDeviceSerializer(serializers.Serializer):
    """Serializer for trusted Bluetooth devices."""
    name = serializers.CharField(max_length=100)
    mac_address = serializers.CharField(max_length=17)
