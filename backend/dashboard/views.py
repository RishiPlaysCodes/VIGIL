"""Dashboard views — Production-grade with AI analytics."""
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone
from django.db.models import Avg, Count, Q
from datetime import timedelta

from alerts.models import Alert
from contacts.models import EmergencyContact
from location.models import UserLocation, LiveTrackingSession


class DashboardView(APIView):
    """Comprehensive dashboard with AI-powered analytics."""

    def get(self, request):
        user = request.user
        now = timezone.now()
        last_24h = now - timedelta(hours=24)
        last_7d = now - timedelta(days=7)
        last_30d = now - timedelta(days=30)

        # Alert stats
        alerts = Alert.objects.filter(user=user)
        total_alerts = alerts.count()
        recent_alerts = alerts.filter(triggered_at__gte=last_24h).count()
        active_alerts = alerts.filter(
            status__in=['triggered', 'emergency_active']
        ).count()

        # AI Performance stats
        ai_stats = alerts.aggregate(
            avg_confidence=Avg('threat_confidence'),
            avg_extraction_score=Avg('extraction_score'),
        )
        face_auto_cancelled = alerts.filter(status='face_verified').count()
        false_alarms = alerts.filter(status='false_alarm').count()
        false_alarm_rate = (false_alarms / total_alerts * 100) if total_alerts > 0 else 0

        # Contact stats
        total_contacts = EmergencyContact.objects.filter(user=user).count()

        # Location stats
        latest_location = UserLocation.objects.filter(user=user).first()
        active_tracking = LiveTrackingSession.objects.filter(
            user=user, is_active=True
        ).exists()

        # Weekly alert breakdown
        weekly_alerts = []
        for i in range(7):
            day_start = now - timedelta(days=i+1)
            day_end = now - timedelta(days=i)
            count = alerts.filter(
                triggered_at__gte=day_start, triggered_at__lt=day_end
            ).count()
            weekly_alerts.append({
                'date': day_start.strftime('%Y-%m-%d'),
                'day': day_start.strftime('%a'),
                'count': count,
            })

        # Protection score
        protection_score = user.protection_score

        # Days since last alert
        last_alert = alerts.first()
        days_safe = (now - last_alert.triggered_at).days if last_alert else user.days_protected

        return Response({
            'user': {
                'username': user.username,
                'pocket_mode_enabled': user.pocket_mode_enabled,
                'battery_saver_mode': user.battery_saver_mode,
                'high_security_mode': user.high_security_mode,
                'protection_score': protection_score,
                'guardian_character': user.guardian_character,
                'face_enrolled': user.face_enrolled,
                'days_protected': user.days_protected,
            },
            'stats': {
                'total_alerts': total_alerts,
                'recent_alerts_24h': recent_alerts,
                'active_alerts': active_alerts,
                'total_contacts': total_contacts,
                'days_safe': days_safe,
            },
            'ai_performance': {
                'avg_threat_confidence': round((ai_stats['avg_confidence'] or 0) * 100, 1),
                'avg_extraction_score': round((ai_stats['avg_extraction_score'] or 0) * 100, 1),
                'face_auto_cancelled': face_auto_cancelled,
                'false_alarm_rate': round(false_alarm_rate, 1),
                'false_alarms_total': false_alarms,
                'ai_accuracy': round(100 - false_alarm_rate, 1),
            },
            'location': {
                'latitude': str(latest_location.latitude) if latest_location else None,
                'longitude': str(latest_location.longitude) if latest_location else None,
                'address': latest_location.address if latest_location else None,
                'speed': latest_location.speed if latest_location else None,
                'google_maps_link': latest_location.google_maps_link if latest_location else None,
                'timestamp': latest_location.timestamp.isoformat() if latest_location else None,
                'active_tracking': active_tracking,
            },
            'weekly_alerts': weekly_alerts,
        })
