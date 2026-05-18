"""Alert notification services — Production-grade with retry logic."""
import logging
import threading
import time
from django.conf import settings
from django.core.mail import send_mail
from django.utils import timezone

logger = logging.getLogger('alerts')


def send_alert_notifications(alert):
    """Send notifications to all emergency contacts with retry logic."""
    # Run in background thread to not block the API response
    thread = threading.Thread(
        target=_send_notifications_async,
        args=(alert.id,),
        daemon=True,
    )
    thread.start()


def _send_notifications_async(alert_id):
    """Background notification sender with retries."""
    from .models import Alert
    try:
        alert = Alert.objects.select_related('user').get(id=alert_id)
    except Alert.DoesNotExist:
        logger.error(f"Alert {alert_id} not found for notification")
        return

    user = alert.user
    contacts = user.emergency_contacts.all()
    notified = []
    sms_sent = False
    email_sent = False

    # Generate tracking link if live session exists
    from location.models import LiveTrackingSession
    import secrets
    tracking_session = LiveTrackingSession.objects.create(
        user=user,
        share_token=secrets.token_urlsafe(32),
        triggered_by='emergency',
        shared_with=[c.id for c in contacts],
    )
    live_link = tracking_session.live_link

    for contact in contacts:
        try:
            # SMS with retry
            if contact.notify_by_sms and contact.phone_number:
                success = _send_sms_with_retry(contact, alert, live_link)
                if success:
                    sms_sent = True

            # Email
            if contact.notify_by_email and contact.email:
                success = _send_email_alert(contact, alert, live_link)
                if success:
                    email_sent = True

            notified.append({
                'name': contact.name,
                'phone': contact.phone_number,
                'email': contact.email,
                'sms_sent': sms_sent,
                'email_sent': email_sent,
            })
        except Exception as e:
            logger.error(f"Failed to notify {contact.name}: {e}")

    # Update alert record
    alert.contacts_notified = notified
    alert.sms_sent = sms_sent
    alert.email_sent = email_sent
    alert.save(update_fields=['contacts_notified', 'sms_sent', 'email_sent'])
    logger.info(f"Alert {alert_id}: Notified {len(notified)} contacts")


def _send_sms_with_retry(contact, alert, live_link, max_retries=None):
    """Send SMS with configurable retry logic."""
    if max_retries is None:
        max_retries = getattr(settings, 'SMS_MAX_RETRIES', 3)
    retry_delay = getattr(settings, 'SMS_RETRY_DELAY_SECONDS', 30)

    message = _build_sms_message(alert, live_link)

    for attempt in range(max_retries):
        try:
            provider = settings.SMS_PROVIDER
            if provider == 'msg91':
                _send_via_msg91(contact.phone_number, message)
            elif provider == 'twilio':
                _send_via_twilio(contact.phone_number, message)
            else:
                logger.warning(f"Unknown SMS provider: {provider}")
                return False

            logger.info(f"SMS sent to {contact.phone_number} (attempt {attempt + 1})")
            # Update retry count on alert
            alert.sms_retry_count = attempt + 1
            alert.save(update_fields=['sms_retry_count'])
            return True

        except Exception as e:
            logger.warning(f"SMS attempt {attempt + 1}/{max_retries} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(retry_delay)

    logger.error(f"SMS failed after {max_retries} attempts to {contact.phone_number}")
    return False


def _build_sms_message(alert, live_link):
    """Build emergency SMS message."""
    username = alert.user.username
    address = alert.address or f"{alert.latitude},{alert.longitude}"
    time_str = alert.triggered_at.strftime('%H:%M')

    return (
        f"VIGIL EMERGENCY: {username} may be in danger!\n"
        f"Location: {address}\n"
        f"Live Track: {live_link}\n"
        f"Time: {time_str}\n"
        f"Confidence: {int(alert.threat_confidence * 100)}%\n"
        f"Check immediately!"
    )


def _send_via_msg91(phone_number, message):
    """Send SMS via MSG91 with proper error handling."""
    import requests

    auth_key = settings.MSG91_AUTH_KEY
    if not auth_key:
        raise ValueError("MSG91 auth key not configured")

    url = "https://api.msg91.com/api/v5/flow/"
    headers = {"authkey": auth_key, "Content-Type": "application/json"}
    payload = {
        "sender": settings.MSG91_SENDER_ID,
        "route": "4",
        "country": "91",
        "sms": [{"message": message, "to": [phone_number]}]
    }

    response = requests.post(url, json=payload, headers=headers, timeout=30)
    response.raise_for_status()


def _send_via_twilio(phone_number, message):
    """Send SMS via Twilio."""
    from twilio.rest import Client

    client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
    client.messages.create(
        body=message,
        from_=settings.TWILIO_PHONE_NUMBER,
        to=phone_number,
    )


def _send_email_alert(contact, alert, live_link):
    """Send email alert with rich content."""
    subject = f"VIGIL EMERGENCY - {alert.user.username} needs help!"

    address = alert.address or f"{alert.latitude}, {alert.longitude}"
    maps_link = f"https://maps.google.com/?q={alert.latitude},{alert.longitude}"

    message = (
        f"VIGIL EMERGENCY ALERT\n"
        f"{'=' * 40}\n\n"
        f"User: {alert.user.username}\n"
        f"Time: {alert.triggered_at.strftime('%H:%M %d/%m/%Y')}\n"
        f"Status: Emergency Protocol Active\n"
        f"AI Confidence: {int(alert.threat_confidence * 100)}%\n\n"
        f"LOCATION\n"
        f"Address: {address}\n"
        f"Google Maps: {maps_link}\n"
        f"Live Tracking: {live_link}\n\n"
        f"WHAT HAPPENED\n"
        f"Trigger: {alert.get_trigger_type_display()}\n"
        f"Reason: {alert.ai_reason or 'Suspicious extraction detected'}\n\n"
        f"WHAT TO DO\n"
        f"1. Check the live tracking link above\n"
        f"2. Try calling {alert.user.username}\n"
        f"3. If no response, contact local authorities\n"
        f"4. Share the tracking link with police if needed\n\n"
        f"This alert was generated automatically by Vigil Safety App.\n"
        f"{'=' * 40}\n"
    )

    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[contact.email],
            fail_silently=False,
        )
        logger.info(f"Email sent to {contact.email}")
        return True
    except Exception as e:
        logger.error(f"Email failed for {contact.email}: {e}")
        return False
