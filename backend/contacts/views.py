"""Views for contacts app."""
from rest_framework import viewsets
from .models import EmergencyContact
from .serializers import EmergencyContactSerializer


class EmergencyContactViewSet(viewsets.ModelViewSet):
    """CRUD endpoints for emergency contacts."""
    serializer_class = EmergencyContactSerializer

    def get_queryset(self):
        return EmergencyContact.objects.filter(user=self.request.user)
