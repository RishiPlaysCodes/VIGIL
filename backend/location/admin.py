"""Admin for location."""
from django.contrib import admin
from .models import UserLocation


@admin.register(UserLocation)
class UserLocationAdmin(admin.ModelAdmin):
    list_display = ['user', 'latitude', 'longitude', 'battery_level', 'is_moving', 'timestamp']
    list_filter = ['is_moving', 'timestamp']
    search_fields = ['user__username']
