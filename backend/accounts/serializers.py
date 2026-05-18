"""Serializers for accounts app."""
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
    """Serializer for user profile."""
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'phone_number', 'profile_image',
            'safety_avatar', 'pocket_mode_enabled', 'grace_period_seconds',
            'schedule_enabled', 'schedule_start_time', 'schedule_end_time',
            'schedule_days', 'battery_saver_mode', 'high_security_mode',
            'location_sharing_enabled', 'continuous_location_sync',
            'custom_ringtone', 'lock_screen_image', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class UserSettingsSerializer(serializers.ModelSerializer):
    """Serializer for updating user settings."""
    class Meta:
        model = User
        fields = [
            'pocket_mode_enabled', 'grace_period_seconds',
            'schedule_enabled', 'schedule_start_time', 'schedule_end_time',
            'schedule_days', 'battery_saver_mode', 'high_security_mode',
            'location_sharing_enabled', 'continuous_location_sync',
            'custom_ringtone', 'safety_avatar'
        ]
