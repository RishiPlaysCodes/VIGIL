"""Admin for contacts."""
from django.contrib import admin
from .models import EmergencyContact


@admin.register(EmergencyContact)
class EmergencyContactAdmin(admin.ModelAdmin):
    list_display = ['name', 'user', 'phone_number', 'relationship', 'is_primary']
    list_filter = ['relationship', 'is_primary']
    search_fields = ['name', 'phone_number', 'user__username']
