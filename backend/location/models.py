"""Location models for continuous tracking."""
from django.db import models
from django.conf import settings


class UserLocation(models.Model):
    """Stores user's location updates for continuous sync."""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='locations'
    )
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    accuracy = models.FloatField(blank=True, null=True)
    altitude = models.FloatField(blank=True, null=True)
    speed = models.FloatField(blank=True, null=True)
    battery_level = models.IntegerField(blank=True, null=True)
    is_moving = models.BooleanField(default=False)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']
        verbose_name = 'User Location'
        verbose_name_plural = 'User Locations'
        indexes = [
            models.Index(fields=['user', '-timestamp']),
        ]

    def __str__(self):
        return f"{self.user.username} @ ({self.latitude}, {self.longitude}) - {self.timestamp}"
