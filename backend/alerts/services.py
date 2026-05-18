"""Alert notification services."""
import logging
from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string

logger = logging.getLogger(__name__)


def send_alert_notifications(alert):
    """Send notifications to all emergency contacts for this alert."""
    user = alert.user
    contacts = user.emergency_contacts.all()
    notified = []

    for contact in contacts:
        try:
            if contact.notify_by_sms and contact.phone_number:
                send_sms_alert(contact, alert)
            if contact.notify_by_email and contact.email:
                send_email_alert(contact, alert)
            notified.append({
                'name': contact.name,
                'phone': contact.phone_number,
                'email': contact.email,
            })
        except Exception as e:
            logger.error(f"Failed to notify {contact.name}: {e}")

    alert.contacts_notified = notified
    alert.sms_sent = any(c.notify_by_sms for c in contacts)
    alert.email_sent = any(c.notify_by_email for c in contacts)
    alert.save()


def send_sms_alert(contact, alert):
    """Send SMS alert to a contact."""
    message = (
        f"VIGIL ALERT: {alert.user.username} may be in danger! "
        f"Location: https://maps.google.com/?q={alert.latitude},{alert.longitude} "
        f"Time: {alert.triggered_at.strftime('%H:%M %d/%m/%Y')} "
        f"Please check on them immediately."
    )

    provider = settings.SMS_PROVIDER
    
    if provider == 'msg91':
        _send_via_msg91(contact.phone_number, message)
    elif provider == 'twilio':
        _send_via_twilio(contact.phone_number, message)
    else:
        logger.warning(f"SMS provider '{provider}' not configured. Message: {message}")


def _send_via_msg91(phone_number, message):
    """Send SMS via MSG91."""
    import requests
    
    auth_key = settings.MSG91_AUTH_KEY
    if not auth_key:
        logger.warning("MSG91 auth key not configured. Skipping SMS.")
        return

    url = "https://api.msg91.com/api/v5/flow/"
    headers = {"authkey": auth_key, "Content-Type": "application/json"}
    payload = {
        "sender": settings.MSG91_SENDER_ID,
        "route": "4",
        "country": "91",
        "sms": [{"message": message, "to": [phone_number]}]
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        logger.info(f"SMS sent to {phone_number} via MSG91")
    except Exception as e:
        logger.error(f"MSG91 SMS failed: {e}")


def _send_via_twilio(phone_number, message):
    """Send SMS via Twilio."""
    try:
        from twilio.rest import Client
        
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        client.messages.create(
            body=message,
            from_=settings.TWILIO_PHONE_NUMBER,
            to=phone_number
        )
        logger.info(f"SMS sent to {phone_number} via Twilio")
    except ImportError:
        logger.error("Twilio library not installed. Run: pip install twilio")
    except Exception as e:
        logger.error(f"Twilio SMS failed: {e}")


def send_email_alert(contact, alert):
    """Send email alert to a contact."""
    subject = f"VIGIL EMERGENCY ALERT - {alert.user.username}"
    
    message = (
        f"Emergency Alert from Vigil Safety App\n\n"
        f"User: {alert.user.username}\n"
        f"Time: {alert.triggered_at.strftime('%H:%M %d/%m/%Y')}\n"
        f"Status: {alert.get_status_display()}\n\n"
        f"Location: https://maps.google.com/?q={alert.latitude},{alert.longitude}\n\n"
        f"The phone's anti-theft system was triggered. "
        f"Please check on {alert.user.username} immediately.\n\n"
        f"- Vigil Safety System"
    )

    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[contact.email],
            fail_silently=False,
        )
        logger.info(f"Email alert sent to {contact.email}")
    except Exception as e:
        logger.error(f"Email alert failed for {contact.email}: {e}")
