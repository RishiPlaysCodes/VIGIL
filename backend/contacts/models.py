"""Emergency contact models."""
from django.db import models
from django.conf import settings


class EmergencyContact(models.Model):
    """Trusted contact who receives alerts."""
    RELATIONSHIP_CHOICES = [
        ('parent', 'Parent'),
        ('guardian', 'Guardian'),
        ('spouse', 'Spouse'),
        ('sibling', 'Sibling'),
        ('friend', 'Friend'),
        ('other', 'Other'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='emergency_contacts'
    )
    name = models.CharField(max_length=100)
    phone_number = models.CharField(max_length=15)
    email = models.EmailField(blank=True, null=True)
    relationship = models.CharField(max_length=20, choices=RELATIONSHIP_CHOICES, default='other')
    is_primary = models.BooleanField(default=False)
    notify_by_sms = models.BooleanField(default=True)
    notify_by_email = models.BooleanField(default=True)
    notify_by_call = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-is_primary', '-created_at']
        verbose_name = 'Emergency Contact'
        verbose_name_plural = 'Emergency Contacts'

    def __str__(self):
        return f"{self.name} ({self.relationship}) - {self.phone_number}"
