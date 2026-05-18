"""Alert models for Vigil."""
from django.db import models
from django.conf import settings


class Alert(models.Model):
    """Represents a triggered security alert."""
    STATUS_CHOICES = [
        ('triggered', 'Triggered'),
        ('acknowledged', 'Acknowledged'),
        ('cancelled', 'Cancelled by Owner'),
        ('resolved', 'Resolved'),
        ('false_alarm', 'False Alarm'),
    ]

    TRIGGER_CHOICES = [
        ('pocket_removal', 'Pocket Removal Detected'),
        ('manual', 'Manual Trigger'),
        ('schedule', 'Scheduled Alert'),
        ('shake', 'Shake Detection'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='alerts'
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='triggered')
    trigger_type = models.CharField(max_length=20, choices=TRIGGER_CHOICES, default='pocket_removal')
    
    # Location at time of alert
    latitude = models.DecimalField(max_digits=10, decimal_places=7, blank=True, null=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    
    # Intruder evidence
    intruder_photo = models.ImageField(upload_to='intruder_photos/', blank=True, null=True)
    
    # Sensor data at trigger
    proximity_value = models.FloatField(blank=True, null=True)
    light_value = models.FloatField(blank=True, null=True)
    accelerometer_data = models.JSONField(blank=True, null=True)
    
    # Notification tracking
    sms_sent = models.BooleanField(default=False)
    email_sent = models.BooleanField(default=False)
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

    def __str__(self):
        return f"Alert #{self.id} - {self.user.username} - {self.status} ({self.triggered_at})"


class LocationHistory(models.Model):
    """Track location during an active alert."""
    alert = models.ForeignKey(Alert, on_delete=models.CASCADE, related_name='location_history')
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    accuracy = models.FloatField(blank=True, null=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']
        verbose_name = 'Location History'
        verbose_name_plural = 'Location Histories'
