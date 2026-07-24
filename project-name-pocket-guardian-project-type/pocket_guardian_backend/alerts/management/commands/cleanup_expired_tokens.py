"""Management command to clean up expired API tokens.

Usage:
    python manage.py cleanup_expired_tokens

Recommended: Run daily via cron or scheduled task.
"""

from datetime import timedelta

from django.conf import settings
from django.core.management.base import BaseCommand
from django.utils import timezone

from alerts.models import ApiToken


class Command(BaseCommand):
    help = "Remove expired API tokens from the database."

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Show what would be deleted without actually deleting.",
        )

    def handle(self, *args, **options):
        expiry_seconds = getattr(settings, "API_TOKEN_EXPIRY_SECONDS", 30 * 24 * 3600)
        cutoff = timezone.now() - timedelta(seconds=expiry_seconds)

        expired_tokens = ApiToken.objects.filter(created_at__lt=cutoff)
        count = expired_tokens.count()

        if options["dry_run"]:
            self.stdout.write(
                self.style.WARNING(f"Would delete {count} expired token(s).")
            )
            return

        expired_tokens.delete()
        self.stdout.write(
            self.style.SUCCESS(f"Deleted {count} expired token(s).")
        )
