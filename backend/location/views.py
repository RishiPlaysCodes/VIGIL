"""Views for location app — Real-time tracking with route and live sessions."""
from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.throttling import ScopedRateThrottle
from django.utils import timezone
from datetime import timedelta

from .models import UserLocation, LiveTrackingSession
from .serializers import (
    UserLocationSerializer, LiveTrackingSessionSerializer,
    LocationRouteSerializer,
)


class LocationUpdateThrottle(ScopedRateThrottle):
    scope = 'location_update'


class LocationUpdateView(generics.CreateAPIView):
    """Receive location updates from the device."""
    serializer_class = UserLocationSerializer
    throttle_classes = [LocationUpdateThrottle]


class LocationHistoryView(generics.ListAPIView):
    """Get location history with filtering."""
    serializer_class = UserLocationSerializer

    def get_queryset(self):
        qs = UserLocation.objects.filter(user=self.request.user)
        # Optional time range filter
        hours = self.request.query_params.get('hours')
        if hours:
            cutoff = timezone.now() - timedelta(hours=int(hours))
            qs = qs.filter(timestamp__gte=cutoff)
        return qs[:500]


class LatestLocationView(APIView):
    """Get the latest known location with address."""

    def get(self, request):
        location = UserLocation.objects.filter(user=request.user).first()
        if location:
            return Response({
                'latitude': str(location.latitude),
                'longitude': str(location.longitude),
                'accuracy': location.accuracy,
                'speed': location.speed,
                'speed_kmh': location.speed_kmh,
                'speed_classification': location.speed_classification,
                'bearing': location.bearing,
                'altitude': location.altitude,
                'battery_level': location.battery_level,
                'is_moving': location.is_moving,
                'address': location.address,
                'google_maps_link': location.google_maps_link,
                'timestamp': location.timestamp.isoformat(),
            })
        return Response({'detail': 'No location data'}, status=status.HTTP_404_NOT_FOUND)


class BulkLocationUpdateView(APIView):
    """Receive bulk location updates (for offline sync)."""
    throttle_classes = [LocationUpdateThrottle]

    def post(self, request):
        locations = request.data.get('locations', [])
        if not locations:
            return Response({'error': 'No locations provided'}, status=status.HTTP_400_BAD_REQUEST)

        created_count = 0
        errors = []

        for loc_data in locations:
            serializer = UserLocationSerializer(data=loc_data, context={'request': request})
            if serializer.is_valid():
                serializer.save()
                created_count += 1
            else:
                errors.append(serializer.errors)

        return Response({
            'created': created_count,
            'errors': len(errors),
            'error_details': errors[:5] if errors else [],
        }, status=status.HTTP_201_CREATED)


class RouteView(APIView):
    """Get route coordinates for map polyline display."""

    def get(self, request):
        hours = int(request.query_params.get('hours', 1))
        cutoff = timezone.now() - timedelta(hours=hours)

        locations = UserLocation.objects.filter(
            user=request.user,
            timestamp__gte=cutoff,
        ).order_by('timestamp').values('latitude', 'longitude', 'timestamp', 'speed')

        route = [{
            'lat': float(loc['latitude']),
            'lng': float(loc['longitude']),
            'speed': loc['speed'],
            'time': loc['timestamp'].isoformat(),
        } for loc in locations]

        # Calculate total distance
        total_distance = 0
        for i in range(1, len(route)):
            total_distance += _haversine(
                route[i-1]['lat'], route[i-1]['lng'],
                route[i]['lat'], route[i]['lng'],
            )

        return Response({
            'route': route,
            'point_count': len(route),
            'total_distance_meters': round(total_distance, 1),
            'duration_hours': hours,
        })


class LiveTrackingSessionView(APIView):
    """Manage live tracking sessions."""

    def get(self, request):
        """Get active tracking sessions."""
        sessions = LiveTrackingSession.objects.filter(
            user=request.user, is_active=True
        )
        serializer = LiveTrackingSessionSerializer(sessions, many=True)
        return Response(serializer.data)

    def post(self, request):
        """Create a new live tracking session."""
        import secrets
        session = LiveTrackingSession.objects.create(
            user=request.user,
            share_token=secrets.token_urlsafe(32),
            triggered_by=request.data.get('triggered_by', 'manual'),
            shared_with=request.data.get('shared_with', []),
        )
        return Response({
            'id': str(session.id),
            'share_token': session.share_token,
            'live_link': session.live_link,
            'started_at': session.started_at.isoformat(),
        }, status=status.HTTP_201_CREATED)

    def delete(self, request):
        """End all active tracking sessions."""
        LiveTrackingSession.objects.filter(
            user=request.user, is_active=True
        ).update(is_active=False, ended_at=timezone.now())
        return Response({'status': 'All sessions ended'})


class PublicTrackingView(APIView):
    """Public endpoint for contacts to view live tracking (no auth required)."""
    permission_classes = [permissions.AllowAny]

    def get(self, request, share_token):
        try:
            session = LiveTrackingSession.objects.get(
                share_token=share_token, is_active=True
            )
        except LiveTrackingSession.DoesNotExist:
            return Response(
                {'error': 'Tracking session not found or expired'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get latest location
        latest = UserLocation.objects.filter(user=session.user).first()
        if not latest:
            return Response({'error': 'No location data available'})

        # Get recent route (last 30 min)
        cutoff = timezone.now() - timedelta(minutes=30)
        route = UserLocation.objects.filter(
            user=session.user, timestamp__gte=cutoff
        ).order_by('timestamp').values('latitude', 'longitude', 'timestamp', 'speed')

        return Response({
            'username': session.user.username,
            'session_started': session.started_at.isoformat(),
            'triggered_by': session.triggered_by,
            'current': {
                'latitude': str(latest.latitude),
                'longitude': str(latest.longitude),
                'address': latest.address,
                'speed': latest.speed,
                'speed_kmh': latest.speed_kmh,
                'battery_level': latest.battery_level,
                'google_maps_link': latest.google_maps_link,
                'last_updated': latest.timestamp.isoformat(),
            },
            'route': [{
                'lat': float(loc['latitude']),
                'lng': float(loc['longitude']),
                'time': loc['timestamp'].isoformat(),
            } for loc in route],
        })


def _haversine(lat1, lon1, lat2, lon2):
    """Calculate distance between two coordinates in meters."""
    import math
    R = 6371000
    dLat = math.radians(lat2 - lat1)
    dLon = math.radians(lon2 - lon1)
    a = (math.sin(dLat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dLon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c
