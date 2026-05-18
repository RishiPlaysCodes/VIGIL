"""User models for Vigil."""
from django.contrib.auth.models import AbstractUser
from django.db import models


class VigilUser(AbstractUser):
    """Custom user model for Vigil app."""
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    profile_image = models.ImageField(upload_to='profiles/', blank=True, null=True)
    safety_avatar = models.CharField(max_length=50, default='default')
    
    # Pocket Mode Settings
    pocket_mode_enabled = models.BooleanField(default=False)
    grace_period_seconds = models.IntegerField(default=3)  # 3, 5, 10, 20
    
    # Schedule Settings
    schedule_enabled = models.BooleanField(default=False)
    schedule_start_time = models.TimeField(blank=True, null=True)
    schedule_end_time = models.TimeField(blank=True, null=True)
    schedule_days = models.JSONField(default=list)  # ['mon', 'tue', ...]
    
    # Battery & Security
    battery_saver_mode = models.BooleanField(default=False)
    high_security_mode = models.BooleanField(default=False)
    
    # Location Settings
    location_sharing_enabled = models.BooleanField(default=True)
    continuous_location_sync = models.BooleanField(default=True)
    
    # Custom ringtone
    custom_ringtone = models.CharField(max_length=200, default='default_alarm')
    
    # Lock screen
    lock_screen_image = models.ImageField(upload_to='lock_screens/', blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Vigil User'
        verbose_name_plural = 'Vigil Users'

    def __str__(self):
        return f"{self.username} ({self.phone_number or 'No phone'})"
