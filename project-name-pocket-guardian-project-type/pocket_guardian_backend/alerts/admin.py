from django.contrib import admin

from .models import Alert, ApiToken, EmergencyContact, LocationPing, NotificationRecord


@admin.register(EmergencyContact)
class EmergencyContactAdmin(admin.ModelAdmin):
    list_display = ("name", "user", "phone_number", "relationship", "is_primary")
    list_filter = ("is_primary",)
    search_fields = ("name", "phone_number", "user__username")


@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):
    list_display = ("user", "reason", "status", "occurred_at")
    list_filter = ("status", "occurred_at")
    search_fields = ("user__username", "reason")


@admin.register(NotificationRecord)
class NotificationRecordAdmin(admin.ModelAdmin):
    list_display = ("alert", "contact", "channel", "status", "created_at")
    list_filter = ("channel", "status", "created_at")


@admin.register(ApiToken)
class ApiTokenAdmin(admin.ModelAdmin):
    list_display = ("user", "created_at")


@admin.register(LocationPing)
class LocationPingAdmin(admin.ModelAdmin):
    list_display = ("user", "latitude", "longitude", "recorded_at")
    list_filter = ("recorded_at",)
