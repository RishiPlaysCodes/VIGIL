from dataclasses import dataclass
import base64
import json
import os
from urllib import parse, request


@dataclass
class SmsResult:
    success: bool
    provider_message_id: str = ""
    error_message: str = ""


class BaseSmsProvider:
    def send(self, phone_number: str, message: str) -> SmsResult:
        raise NotImplementedError


class ConsoleSmsProvider(BaseSmsProvider):
    def send(self, phone_number: str, message: str) -> SmsResult:
        print(f"[SMS to {phone_number}] {message}")
        return SmsResult(success=True, provider_message_id="console")


class TwilioSmsProvider(BaseSmsProvider):
    def __init__(self) -> None:
        self.account_sid = os.getenv("TWILIO_ACCOUNT_SID", "")
        self.auth_token = os.getenv("TWILIO_AUTH_TOKEN", "")
        self.from_number = os.getenv("TWILIO_FROM_NUMBER", "")

    def send(self, phone_number: str, message: str) -> SmsResult:
        if not self.account_sid or not self.auth_token or not self.from_number:
            return SmsResult(success=False, error_message="Twilio credentials missing.")
        payload = parse.urlencode(
            {"To": phone_number, "From": self.from_number, "Body": message}
        ).encode()
        url = (
            "https://api.twilio.com/2010-04-01/Accounts/"
            f"{self.account_sid}/Messages.json"
        )
        encoded = base64.b64encode(
            f"{self.account_sid}:{self.auth_token}".encode()
        ).decode()
        sms_request = request.Request(
            url,
            data=payload,
            headers={"Authorization": f"Basic {encoded}"},
            method="POST",
        )
        try:
            with request.urlopen(sms_request, timeout=10) as response:
                body = json.loads(response.read().decode())
            return SmsResult(
                success=True,
                provider_message_id=body.get("sid", ""),
            )
        except Exception as error:  # pragma: no cover - provider/network dependent
            return SmsResult(success=False, error_message=str(error))


class Msg91SmsProvider(BaseSmsProvider):
    def __init__(self) -> None:
        self.authkey = os.getenv("MSG91_AUTHKEY", "")
        self.sender = os.getenv("MSG91_SENDER_ID", "")
        self.route = os.getenv("MSG91_ROUTE", "4")
        self.country = os.getenv("MSG91_COUNTRY", "91")

    def send(self, phone_number: str, message: str) -> SmsResult:
        if not self.authkey or not self.sender:
            return SmsResult(success=False, error_message="MSG91 credentials missing.")
        normalized_phone = "".join(character for character in phone_number if character.isdigit())
        payload = json.dumps(
            {
                "sender": self.sender,
                "route": self.route,
                "country": self.country,
                "sms": [{"message": message, "to": [normalized_phone]}],
            }
        ).encode()
        sms_request = request.Request(
            "https://api.msg91.com/api/v2/sendsms",
            data=payload,
            headers={
                "authkey": self.authkey,
                "content-type": "application/json",
            },
            method="POST",
        )
        try:
            with request.urlopen(sms_request, timeout=10) as response:
                body = json.loads(response.read().decode())
            if body.get("type") == "error":
                return SmsResult(success=False, error_message=body.get("message", "MSG91 error"))
            return SmsResult(
                success=True,
                provider_message_id=body.get("message", ""),
            )
        except Exception as error:  # pragma: no cover - provider/network dependent
            return SmsResult(success=False, error_message=str(error))


def get_sms_provider() -> BaseSmsProvider:
    provider = os.getenv("SMS_PROVIDER", "console").lower()
    if provider == "msg91":
        return Msg91SmsProvider()
    if provider == "twilio":
        return TwilioSmsProvider()
    return ConsoleSmsProvider()
