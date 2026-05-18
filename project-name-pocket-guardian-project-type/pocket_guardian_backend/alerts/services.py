from django.conf import settings
from django.core.mail import EmailMessage
from django.utils import timezone

from .models import NotificationRecord
from .providers import get_sms_provider


def process_notification(notification: NotificationRecord) -> NotificationRecord:
    contact = notification.contact

    if notification.channel == NotificationRecord.Channel.EMAIL:
        if contact is None or not contact.email:
            notification.status = NotificationRecord.Status.FAILED
            notification.error_message = "No contact email available."
            notification.save(update_fields=["status", "error_message"])
            return notification

        try:
            email = EmailMessage(
                subject="Pocket Guardian emergency alert",
                body=notification.message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[contact.email],
            )
            if notification.alert.photo:
                email.attach_file(notification.alert.photo.path)
            email.send(fail_silently=False)
            notification.status = NotificationRecord.Status.SENT
            notification.sent_at = timezone.now()
            notification.error_message = ""
        except Exception as error:  # pragma: no cover - provider dependent
            notification.status = NotificationRecord.Status.FAILED
            notification.error_message = str(error)

        notification.save(update_fields=["status", "sent_at", "error_message"])
        return notification

    if notification.channel == NotificationRecord.Channel.SMS:
        if contact is None or not contact.phone_number:
            notification.status = NotificationRecord.Status.FAILED
            notification.error_message = "No contact phone number available."
            notification.save(update_fields=["status", "error_message"])
            return notification

        result = get_sms_provider().send(contact.phone_number, notification.message)
        notification.status = (
            NotificationRecord.Status.SENT
            if result.success
            else NotificationRecord.Status.FAILED
        )
        notification.sent_at = timezone.now() if result.success else None
        notification.error_message = result.error_message
        notification.save(update_fields=["status", "sent_at", "error_message"])
        return notification

    notification.status = NotificationRecord.Status.QUEUED
    notification.save(update_fields=["status"])
    return notification
