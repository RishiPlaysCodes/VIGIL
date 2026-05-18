from django.core.management.base import BaseCommand

from alerts.models import NotificationRecord
from alerts.services import process_notification


class Command(BaseCommand):
    help = "Process queued Pocket Guardian notifications."

    def handle(self, *args, **options):
        queued = NotificationRecord.objects.filter(
            status=NotificationRecord.Status.QUEUED
        )
        processed = 0
        for notification in queued:
            process_notification(notification)
            processed += 1
        self.stdout.write(self.style.SUCCESS(f"Processed {processed} notifications."))
