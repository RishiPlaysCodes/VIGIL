"""Admin configuration for accounts."""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import VigilUser


@admin.register(VigilUser)
class VigilUserAdmin(UserAdmin):
    list_display = ['username', 'email', 'phone_number', 'pocket_mode_enabled', 'created_at']
    list_filter = ['pocket_mode_enabled', 'high_security_mode', 'battery_saver_mode']
    fieldsets = UserAdmin.fieldsets + (
        ('Vigil Settings', {
            'fields': (
                'phone_number', 'profile_image', 'safety_avatar',
                'pocket_mode_enabled', 'grace_period_seconds',
                'schedule_enabled', 'schedule_start_time', 'schedule_end_time',
                'schedule_days', 'battery_saver_mode', 'high_security_mode',
                'location_sharing_enabled', 'continuous_location_sync',
                'custom_ringtone', 'lock_screen_image',
            )
        }),
    )
