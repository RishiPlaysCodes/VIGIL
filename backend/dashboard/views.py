"""Dashboard views for Vigil backend."""
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone
from datetime import timedelta

from alerts.models import Alert
from contacts.models import EmergencyContact
from location.models import UserLocation


class DashboardView(APIView):
    """Main dashboard data endpoint."""

    def get(self, request):
        user = request.user
        now = timezone.now()
        last_24h = now - timedelta(hours=24)
        last_7d = now - timedelta(days=7)

        # Alert stats
        total_alerts = Alert.objects.filter(user=user).count()
        recent_alerts = Alert.objects.filter(user=user, triggered_at__gte=last_24h).count()
        active_alerts = Alert.objects.filter(user=user, status='triggered').count()

        # Contact stats
        total_contacts = EmergencyContact.objects.filter(user=user).count()

        # Location stats
        latest_location = UserLocation.objects.filter(user=user).first()

        # Weekly alert breakdown
        weekly_alerts = []
        for i in range(7):
            day_start = now - timedelta(days=i+1)
            day_end = now - timedelta(days=i)
            count = Alert.objects.filter(
                user=user, triggered_at__gte=day_start, triggered_at__lt=day_end
            ).count()
            weekly_alerts.append({
                'date': day_start.strftime('%Y-%m-%d'),
                'count': count
            })

        return Response({
            'user': {
                'username': user.username,
                'pocket_mode_enabled': user.pocket_mode_enabled,
                'battery_saver_mode': user.battery_saver_mode,
                'high_security_mode': user.high_security_mode,
            },
            'stats': {
                'total_alerts': total_alerts,
                'recent_alerts_24h': recent_alerts,
                'active_alerts': active_alerts,
                'total_contacts': total_contacts,
            },
            'latest_location': {
                'latitude': str(latest_location.latitude) if latest_location else None,
                'longitude': str(latest_location.longitude) if latest_location else None,
                'timestamp': latest_location.timestamp.isoformat() if latest_location else None,
            },
            'weekly_alerts': weekly_alerts,
        })
