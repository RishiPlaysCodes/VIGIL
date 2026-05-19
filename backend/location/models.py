"""Location models — Production-grade with real-time tracking support."""
from django.db import models
from django.conf import settings
import uuid


class UserLocation(models.Model):
    """Stores user's location updates for continuous sync and route tracking."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='locations'
    )
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    accuracy = models.FloatField(blank=True, null=True)
    altitude = models.FloatField(blank=True, null=True)
    speed = models.FloatField(blank=True, null=True)  # m/s
    bearing = models.FloatField(blank=True, null=True)  # degrees
    battery_level = models.IntegerField(blank=True, null=True)
    is_moving = models.BooleanField(default=False)
    address = models.TextField(blank=True, null=True)
    speed_classification = models.CharField(max_length=20, blank=True, null=True,
        choices=[
            ('stationary', 'Stationary'),
            ('walking', 'Walking'),
            ('running', 'Running'),
            ('cycling', 'Cycling'),
            ('driving', 'Driving'),
            ('high_speed', 'High Speed'),
        ])
    tracking_mode = models.CharField(max_length=20, default='normal',
        choices=[('normal', 'Normal'), ('high', 'High'), ('emergency', 'Emergency')])
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']
        verbose_name = 'User Location'
        verbose_name_plural = 'User Locations'
        indexes = [
            models.Index(fields=['user', '-timestamp']),
            models.Index(fields=['user', 'tracking_mode', '-timestamp']),
        ]

    def __str__(self):
        return f"{self.user.username} @ ({self.latitude}, {self.longitude}) - {self.timestamp}"

    @property
    def google_maps_link(self):
        return f"https://maps.google.com/?q={self.latitude},{self.longitude}"

    @property
    def speed_kmh(self):
        return (self.speed or 0) * 3.6


class LiveTrackingSession(models.Model):
    """Represents an active live tracking session shared with contacts."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='tracking_sessions'
    )
    share_token = models.CharField(max_length=64, unique=True)  # Public access token
    is_active = models.BooleanField(default=True)
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(blank=True, null=True)
    triggered_by = models.CharField(max_length=30, default='emergency',
        choices=[('manual', 'Manual'), ('emergency', 'Emergency'), ('schedule', 'Schedule')])
    shared_with = models.JSONField(default=list)  # Contact IDs

    class Meta:
        ordering = ['-started_at']

    def __str__(self):
        return f"Tracking session for {self.user.username} ({self.share_token[:8]}...)"

    @property
    def live_link(self):
        """Generate public tracking link (for SMS/email to contacts)."""
        from django.conf import settings
        base_url = getattr(settings, 'TRACKING_BASE_URL', 'https://vigil.app')
        return f"{base_url}/track/{self.share_token}"
