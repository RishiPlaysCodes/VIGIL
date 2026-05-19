"""User models for Vigil — Production-grade with AI features support."""
from django.contrib.auth.models import AbstractUser
from django.db import models
import uuid


class VigilUser(AbstractUser):
    """Custom user model with full AI safety features."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    profile_image = models.ImageField(upload_to='profiles/', blank=True, null=True)
    safety_avatar = models.CharField(max_length=50, default='cyber_guardian')

    # Pocket Mode Settings
    pocket_mode_enabled = models.BooleanField(default=False)
    grace_period_seconds = models.IntegerField(default=3)
    high_security_mode = models.BooleanField(default=False)
    battery_saver_mode = models.BooleanField(default=False)

    # AI Detection Settings
    ai_sensitivity = models.FloatField(default=0.6)  # 0.0-1.0 extraction threshold
    extraction_confidence_threshold = models.FloatField(default=0.6)
    false_positive_learning = models.BooleanField(default=True)

    # Schedule Settings
    schedule_enabled = models.BooleanField(default=False)
    schedule_start_time = models.TimeField(blank=True, null=True)
    schedule_end_time = models.TimeField(blank=True, null=True)
    schedule_days = models.JSONField(default=list)

    # Location Settings
    location_sharing_enabled = models.BooleanField(default=True)
    continuous_location_sync = models.BooleanField(default=True)
    tracking_mode = models.CharField(max_length=20, default='normal',
        choices=[('normal', 'Normal'), ('high', 'High Accuracy'), ('emergency', 'Emergency')])

    # Authentication Methods
    face_enrolled = models.BooleanField(default=False)
    fingerprint_enabled = models.BooleanField(default=True)
    voice_password_enabled = models.BooleanField(default=False)
    voice_phrase_hash = models.CharField(max_length=256, blank=True, null=True)
    pin_enabled = models.BooleanField(default=False)
    pin_hash = models.CharField(max_length=256, blank=True, null=True)
    required_auth_methods = models.IntegerField(default=1)  # 1, 2, or 3

    # Custom ringtone & appearance
    custom_ringtone = models.CharField(max_length=200, default='default_alarm')
    lock_screen_image = models.ImageField(upload_to='lock_screens/', blank=True, null=True)
    guardian_character = models.CharField(max_length=50, default='cyber_guardian')

    # Safe Zones
    safe_zones = models.JSONField(default=list)  # [{name, lat, lng, radius, type}]

    # Trusted Bluetooth Devices
    trusted_devices = models.JSONField(default=list)  # [{name, mac_address}]

    # Stats
    total_alerts = models.IntegerField(default=0)
    false_alarms = models.IntegerField(default=0)
    days_protected = models.IntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Vigil User'
        verbose_name_plural = 'Vigil Users'

    def __str__(self):
        return f"{self.username} ({self.phone_number or 'No phone'})"

    @property
    def protection_score(self):
        """Calculate a protection readiness score 0-100."""
        score = 0
        if self.face_enrolled: score += 25
        if self.fingerprint_enabled: score += 20
        if self.voice_password_enabled: score += 20
        if self.pin_enabled: score += 10
        if len(self.safe_zones) > 0: score += 10
        if len(self.trusted_devices) > 0: score += 10
        if self.schedule_enabled: score += 5
        return min(score, 100)
