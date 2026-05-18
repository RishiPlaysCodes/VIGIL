from django.core.management.base import BaseCommand, CommandError

from alerts.providers import get_sms_provider


class Command(BaseCommand):
    help = "Send one test SMS through the configured Pocket Guardian SMS provider."

    def add_arguments(self, parser):
        parser.add_argument("phone_number")
        parser.add_argument(
            "--message",
            default="Pocket Guardian test: SMS delivery is working.",
        )

    def handle(self, *args, **options):
        result = get_sms_provider().send(
            options["phone_number"],
            options["message"],
        )
        if not result.success:
            raise CommandError(result.error_message or "SMS sending failed.")
        self.stdout.write(
            self.style.SUCCESS(
                f"SMS sent successfully. Provider id: {result.provider_message_id or 'n/a'}"
            )
        )
