"""Alert models for Vigil — Production-grade with AI evidence tracking."""
from django.db import models
from django.conf import settings
import uuid


class Alert(models.Model):
    """Represents a triggered security alert with full AI context."""
    STATUS_CHOICES = [
        ('triggered', 'Triggered'),
        ('face_verified', 'Auto-cancelled by Face'),
        ('auth_cancelled', 'Cancelled by Auth'),
        ('emergency_active', 'Emergency Protocol Active'),
        ('resolved', 'Resolved'),
        ('false_alarm', 'False Alarm'),
        ('timeout', 'Timed Out'),
    ]

    TRIGGER_CHOICES = [
        ('ai_extraction', 'AI Extraction Detection'),
        ('pocket_removal', 'Pocket Removal'),
        ('manual_sos', 'Manual SOS'),
        ('schedule', 'Scheduled Check'),
        ('geofence', 'Geofence Exit'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='alerts'
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='triggered')
    trigger_type = models.CharField(max_length=20, choices=TRIGGER_CHOICES, default='ai_extraction')

    # AI Confidence Data
    threat_confidence = models.FloatField(default=0.0)
    extraction_score = models.FloatField(default=0.0)
    movement_context = models.CharField(max_length=30, blank=True, null=True)
    ai_reason = models.TextField(blank=True, null=True)

    # Location at time of alert
    latitude = models.DecimalField(max_digits=10, decimal_places=7, blank=True, null=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    speed_at_trigger = models.FloatField(blank=True, null=True)

    # Sensor data at trigger (full snapshot)
    sensor_snapshot = models.JSONField(blank=True, null=True)
    proximity_value = models.FloatField(blank=True, null=True)
    light_value = models.FloatField(blank=True, null=True)
    accel_magnitude = models.FloatField(blank=True, null=True)
    gyro_magnitude = models.FloatField(blank=True, null=True)
    jerk_value = models.FloatField(blank=True, null=True)

    # Verification result
    face_verification_result = models.CharField(max_length=30, blank=True, null=True)
    face_confidence = models.FloatField(blank=True, null=True)
    auth_method_used = models.CharField(max_length=30, blank=True, null=True)

    # Emergency Protocol Data
    emergency_activated = models.BooleanField(default=False)
    emergency_activated_at = models.DateTimeField(blank=True, null=True)
    emergency_deactivated_at = models.DateTimeField(blank=True, null=True)
    photos_captured = models.IntegerField(default=0)
    photos_uploaded = models.IntegerField(default=0)

    # Notification tracking
    sms_sent = models.BooleanField(default=False)
    email_sent = models.BooleanField(default=False)
    sms_retry_count = models.IntegerField(default=0)
    contacts_notified = models.JSONField(default=list)

    # Timestamps
    triggered_at = models.DateTimeField(auto_now_add=True)
    acknowledged_at = models.DateTimeField(blank=True, null=True)
    resolved_at = models.DateTimeField(blank=True, null=True)

    notes = models.TextField(blank=True, null=True)

    class Meta:
        ordering = ['-triggered_at']
        verbose_name = 'Alert'
        verbose_name_plural = 'Alerts'
        indexes = [
            models.Index(fields=['user', '-triggered_at']),
            models.Index(fields=['user', 'status']),
        ]

    def __str__(self):
        return f"Alert {self.id} - {self.user.username} - {self.status}"

    @property
    def duration(self):
        if self.resolved_at and self.triggered_at:
            return self.resolved_at - self.triggered_at
        return None


class AlertEvidence(models.Model):
    """Evidence captured during an alert (photos, video, audio)."""
    EVIDENCE_TYPES = [
        ('photo', 'Photo'),
        ('video', 'Video'),
        ('audio', 'Audio'),
        ('sensor_log', 'Sensor Log'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    alert = models.ForeignKey(Alert, on_delete=models.CASCADE, related_name='evidence')
    evidence_type = models.CharField(max_length=20, choices=EVIDENCE_TYPES)
    file = models.FileField(upload_to='evidence/%Y/%m/%d/')
    thumbnail = models.ImageField(upload_to='evidence/thumbs/', blank=True, null=True)
    metadata = models.JSONField(blank=True, null=True)  # EXIF, duration, etc.
    captured_at = models.DateTimeField()
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-captured_at']
        verbose_name = 'Alert Evidence'
        verbose_name_plural = 'Alert Evidence'

    def __str__(self):
        return f"{self.evidence_type} for Alert {self.alert_id}"


class AlertLocationTrail(models.Model):
    """Continuous location tracking during an active alert."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    alert = models.ForeignKey(Alert, on_delete=models.CASCADE, related_name='location_trail')
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    accuracy = models.FloatField(blank=True, null=True)
    speed = models.FloatField(blank=True, null=True)
    bearing = models.FloatField(blank=True, null=True)
    altitude = models.FloatField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    battery_level = models.IntegerField(blank=True, null=True)
    timestamp = models.DateTimeField()

    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['alert', '-timestamp']),
        ]

    def __str__(self):
        return f"Trail point for Alert {self.alert_id} at {self.timestamp}"
