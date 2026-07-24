import secrets
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone


class EmergencyContact(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="emergency_contacts")
    name = models.CharField(max_length=120)
    phone_number = models.CharField(max_length=30)
    email = models.EmailField(blank=True)
    relationship = models.CharField(max_length=80, blank=True)
    is_primary = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-is_primary", "name"]
        indexes = [
            models.Index(fields=["user", "is_primary"]),
        ]

    def __str__(self) -> str:
        return f"{self.name} ({self.user.username})"


class ApiToken(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="api_token")
    key = models.CharField(max_length=64, unique=True, default=secrets.token_hex)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=["key"]),
        ]

    def __str__(self) -> str:
        return f"Token for {self.user.username}"

    @property
    def is_expired(self) -> bool:
        """Check if token has expired based on settings."""
        expiry_seconds = getattr(settings, 'API_TOKEN_EXPIRY_SECONDS', 30 * 24 * 3600)
        expiry_delta = timedelta(seconds=expiry_seconds)
        return timezone.now() > self.created_at + expiry_delta

    def rotate(self) -> "ApiToken":
        """Generate a new token key and reset the creation timestamp."""
        self.key = secrets.token_hex()
        self.created_at = timezone.now()
        self.save(update_fields=["key", "created_at"])
        return self

    def touch(self) -> None:
        """Update last_used_at timestamp."""
        self.last_used_at = timezone.now()
        self.save(update_fields=["last_used_at"])


class Alert(models.Model):
    class Status(models.TextChoices):
        TRIGGERED = "triggered", "Triggered"
        CANCELLED = "cancelled", "Cancelled"

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="alerts")
    reason = models.CharField(max_length=255)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.TRIGGERED)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    photo_path = models.CharField(max_length=500, blank=True)
    photo = models.ImageField(upload_to="intruder_photos/", blank=True, null=True)
    occurred_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-occurred_at"]
        indexes = [
            models.Index(fields=["user", "-occurred_at"]),
            models.Index(fields=["status"]),
        ]

    def __str__(self) -> str:
        return f"{self.user.username}: {self.reason} @ {self.occurred_at}"


class NotificationRecord(models.Model):
    class Channel(models.TextChoices):
        SMS = "sms", "SMS"
        PUSH = "push", "Push"
        EMAIL = "email", "Email"

    class Status(models.TextChoices):
        QUEUED = "queued", "Queued"
        SENT = "sent", "Sent"
        FAILED = "failed", "Failed"

    alert = models.ForeignKey(Alert, on_delete=models.CASCADE, related_name="notifications")
    contact = models.ForeignKey(
        EmergencyContact,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="notifications",
    )
    channel = models.CharField(max_length=20, choices=Channel.choices, default=Channel.SMS)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.QUEUED)
    message = models.TextField()
    sent_at = models.DateTimeField(null=True, blank=True)
    error_message = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["alert", "channel"]),
            models.Index(fields=["status"]),
        ]

    def __str__(self) -> str:
        return f"{self.channel} {self.status} for alert {self.alert_id}"


class LocationPing(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="location_pings")
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    recorded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-recorded_at"]
        indexes = [
            models.Index(fields=["user", "-recorded_at"]),
        ]

    def __str__(self) -> str:
        return f"{self.user.username}: {self.latitude}, {self.longitude}"
