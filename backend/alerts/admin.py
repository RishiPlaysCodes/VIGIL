"""Admin for alerts."""
from django.contrib import admin
from .models import Alert, LocationHistory


class LocationHistoryInline(admin.TabularInline):
    model = LocationHistory
    extra = 0
    readonly_fields = ['timestamp']


@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'status', 'trigger_type', 'triggered_at', 'sms_sent', 'email_sent']
    list_filter = ['status', 'trigger_type', 'sms_sent', 'email_sent']
    search_fields = ['user__username', 'address']
    readonly_fields = ['triggered_at']
    inlines = [LocationHistoryInline]
