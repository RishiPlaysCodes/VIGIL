from django.contrib.auth.models import User
from django.db import models
import secrets


class EmergencyContact(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="emergency_contacts")
    name = models.CharField(max_length=120)
    phone_number = models.CharField(max_length=30)
    email = models.EmailField(blank=True)
    relationship = models.CharField(max_length=80, blank=True)
    is_primary = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-is_primary", "name"]

    def __str__(self) -> str:
        return f"{self.name} ({self.user.username})"


class ApiToken(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="api_token")
    key = models.CharField(max_length=64, unique=True, default=secrets.token_hex)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return f"Token for {self.user.username}"


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

    def __str__(self) -> str:
        return f"{self.channel} {self.status} for alert {self.alert_id}"


class LocationPing(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="location_pings")
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    recorded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-recorded_at"]

    def __str__(self) -> str:
        return f"{self.user.username}: {self.latitude}, {self.longitude}"
