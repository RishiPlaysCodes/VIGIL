"""Views for location app."""
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import UserLocation
from .serializers import UserLocationSerializer


class LocationUpdateView(generics.CreateAPIView):
    """Receive location updates from the device."""
    serializer_class = UserLocationSerializer


class LocationHistoryView(generics.ListAPIView):
    """Get location history for the current user."""
    serializer_class = UserLocationSerializer

    def get_queryset(self):
        return UserLocation.objects.filter(user=self.request.user)[:100]


class LatestLocationView(APIView):
    """Get the latest known location."""

    def get(self, request):
        location = UserLocation.objects.filter(user=request.user).first()
        if location:
            return Response(UserLocationSerializer(location).data)
        return Response({'detail': 'No location data'}, status=status.HTTP_404_NOT_FOUND)


class BulkLocationUpdateView(APIView):
    """Receive bulk location updates (for offline sync)."""

    def post(self, request):
        locations = request.data.get('locations', [])
        created = []
        for loc_data in locations:
            serializer = UserLocationSerializer(data=loc_data, context={'request': request})
            if serializer.is_valid():
                serializer.save()
                created.append(serializer.data)
        return Response({'created': len(created)}, status=status.HTTP_201_CREATED)
