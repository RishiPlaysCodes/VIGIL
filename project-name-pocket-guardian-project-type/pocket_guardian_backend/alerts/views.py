import json
import logging
from datetime import datetime
from decimal import Decimal, InvalidOperation

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.http import JsonResponse
from django.shortcuts import render
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from .models import Alert, ApiToken, EmergencyContact, LocationPing, NotificationRecord
from .rate_limiter import auth_rate_limiter, get_client_ip
from .services import process_notification

logger = logging.getLogger(__name__)


def _json_body(request):
    try:
        return json.loads(request.body.decode("utf-8") or "{}")
    except json.JSONDecodeError:
        return None


def _bad_request(message):
    return JsonResponse({"error": message}, status=400)


def _request_user(request):
    """Authenticate request via Authorization header token.
    
    Returns None if:
    - No Authorization header present
    - Token not found in database
    - Token has expired
    """
    header = request.headers.get("Authorization", "")
    if not header.startswith("Token "):
        return None
    token_key = header.removeprefix("Token ").strip()
    if not token_key:
        return None
    token = ApiToken.objects.select_related("user").filter(key=token_key).first()
    if token is None:
        return None
    if token.is_expired:
        logger.warning("Expired token used by user %s", token.user.username)
        return None
    # Update last_used timestamp (fire-and-forget, don't block request)
    token.touch()
    return token.user


@csrf_exempt
@require_http_methods(["POST"])
def signup(request):
    client_ip = get_client_ip(request)
    if auth_rate_limiter.is_rate_limited(f"signup:{client_ip}"):
        return JsonResponse(
            {"error": "Too many attempts. Please try again later."},
            status=429,
        )

    payload = _json_body(request)
    if payload is None:
        return _bad_request("Invalid JSON body.")

    username = payload.get("username", "").strip()
    password = payload.get("password", "")
    if not username or not password:
        return _bad_request("username and password are required.")
    if len(username) < 3 or len(username) > 30:
        return _bad_request("username must be 3-30 characters.")
    if len(password) < 8:
        return _bad_request("password must be at least 8 characters.")
    if User.objects.filter(username=username).exists():
        auth_rate_limiter.record_attempt(f"signup:{client_ip}")
        return _bad_request("username already exists.")

    user = User.objects.create_user(username=username, password=password)
    token, _ = ApiToken.objects.get_or_create(user=user)
    logger.info("New user registered: %s from %s", username, client_ip)
    return JsonResponse(
        {"id": user.id, "username": user.username, "token": token.key},
        status=201,
    )


@csrf_exempt
@require_http_methods(["POST"])
def login(request):
    client_ip = get_client_ip(request)
    if auth_rate_limiter.is_rate_limited(f"login:{client_ip}"):
        return JsonResponse(
            {"error": "Too many failed attempts. Please try again later."},
            status=429,
        )

    payload = _json_body(request)
    if payload is None:
        return _bad_request("Invalid JSON body.")

    user = authenticate(
        username=payload.get("username"),
        password=payload.get("password"),
    )
    if user is None:
        auth_rate_limiter.record_attempt(f"login:{client_ip}")
        logger.warning("Failed login attempt for '%s' from %s", payload.get("username", ""), client_ip)
        return JsonResponse({"error": "Invalid credentials."}, status=401)

    auth_rate_limiter.reset(f"login:{client_ip}")
    token, _ = ApiToken.objects.get_or_create(user=user)
    # Rotate token if it's expired
    if token.is_expired:
        token.rotate()
        logger.info("Token rotated for user: %s", user.username)
    logger.info("User logged in: %s from %s", user.username, client_ip)
    return JsonResponse({"id": user.id, "username": user.username, "token": token.key})


@csrf_exempt
@require_http_methods(["GET", "POST"])
def emergency_contacts(request, user_id):
    user = _request_user(request)
    if user is None or user.id != user_id:
        return JsonResponse({"error": "Unauthorized."}, status=401)
    user = User.objects.filter(pk=user_id).first()
    if user is None:
        return JsonResponse({"error": "User not found."}, status=404)

    if request.method == "GET":
        return JsonResponse(
            {
                "contacts": [
                    {
                        "id": contact.id,
                        "name": contact.name,
                        "phone_number": contact.phone_number,
                        "relationship": contact.relationship,
                        "is_primary": contact.is_primary,
                    }
                    for contact in user.emergency_contacts.all()
                ]
            }
        )

    payload = _json_body(request)
    if payload is None:
        return _bad_request("Invalid JSON body.")

    name = payload.get("name", "").strip()
    phone_number = payload.get("phone_number", "").strip()
    if not name or not phone_number:
        return _bad_request("name and phone_number are required.")

    is_primary = bool(payload.get("is_primary", True))
    if is_primary:
        user.emergency_contacts.update(is_primary=False)
    contact, _ = EmergencyContact.objects.update_or_create(
        user=user,
        phone_number=phone_number,
        defaults={
            "name": name,
            "email": payload.get("email", "").strip(),
            "relationship": payload.get("relationship", "").strip(),
            "is_primary": is_primary,
        },
    )
    return JsonResponse(
        {
            "id": contact.id,
            "name": contact.name,
            "phone_number": contact.phone_number,
            "email": contact.email,
            "relationship": contact.relationship,
            "is_primary": contact.is_primary,
        },
        status=201,
    )


@csrf_exempt
@require_http_methods(["GET", "POST"])
def alerts(request, user_id):
    user = _request_user(request)
    if user is None or user.id != user_id:
        return JsonResponse({"error": "Unauthorized."}, status=401)
    user = User.objects.filter(pk=user_id).first()
    if user is None:
        return JsonResponse({"error": "User not found."}, status=404)

    if request.method == "GET":
        return JsonResponse(
            {
                "alerts": [
                    {
                        "id": alert.id,
                        "reason": alert.reason,
                        "status": alert.status,
                        "latitude": str(alert.latitude) if alert.latitude is not None else None,
                        "longitude": str(alert.longitude) if alert.longitude is not None else None,
                        "photo_path": alert.photo_path,
                        "occurred_at": alert.occurred_at.isoformat(),
                    }
                    for alert in user.alerts.all()
                ]
            }
        )

    payload = _json_body(request)
    if payload is None:
        return _bad_request("Invalid JSON body.")

    reason = payload.get("reason", "").strip()
    if not reason:
        return _bad_request("reason is required.")

    try:
        occurred_at_raw = payload.get("occurred_at")
        occurred_at = datetime.fromisoformat(occurred_at_raw) if occurred_at_raw else timezone.now()
        if timezone.is_naive(occurred_at):
            occurred_at = timezone.make_aware(occurred_at)
        latitude = Decimal(str(payload["latitude"])) if payload.get("latitude") is not None else None
        longitude = Decimal(str(payload["longitude"])) if payload.get("longitude") is not None else None
    except (ValueError, TypeError, InvalidOperation):
        return _bad_request("Invalid date or coordinates.")

    alert = Alert.objects.create(
        user=user,
        reason=reason,
        status=payload.get("status", Alert.Status.TRIGGERED),
        latitude=latitude,
        longitude=longitude,
        photo_path=payload.get("photo_path", "").strip(),
        occurred_at=occurred_at,
    )
    primary_contact = user.emergency_contacts.filter(is_primary=True).first()
    if primary_contact is not None:
        message = (
            "Suspicious phone movement/access detected. Please check immediately. "
            f"Location: {latitude}, {longitude}. "
            f"Map: https://maps.google.com/?q={latitude},{longitude}. "
            f"Time: {alert.occurred_at.isoformat()}."
        )
        channels = []
        if primary_contact.email:
            channels.append(NotificationRecord.Channel.EMAIL)
        if primary_contact.phone_number:
            channels.append(NotificationRecord.Channel.SMS)
        for channel in channels:
            notification = NotificationRecord.objects.create(
                alert=alert,
                contact=primary_contact,
                channel=channel,
                status=NotificationRecord.Status.QUEUED,
                message=message,
            )
            process_notification(notification)
    return JsonResponse(
        {
            "id": alert.id,
            "reason": alert.reason,
            "status": alert.status,
            "occurred_at": alert.occurred_at.isoformat(),
        },
        status=201,
    )


@csrf_exempt
@require_http_methods(["POST"])
def upload_alert_photo(request, user_id, alert_id):
    user = _request_user(request)
    if user is None or user.id != user_id:
        return JsonResponse({"error": "Unauthorized."}, status=401)
    alert = Alert.objects.filter(pk=alert_id, user=user).first()
    if alert is None:
        return JsonResponse({"error": "Alert not found."}, status=404)
    photo = request.FILES.get("photo")
    if photo is None:
        return _bad_request("photo is required.")
    alert.photo = photo
    alert.photo_path = alert.photo.name
    alert.save(update_fields=["photo", "photo_path"])
    for notification in alert.notifications.filter(channel=NotificationRecord.Channel.EMAIL):
        process_notification(notification)
    return JsonResponse({"photo_path": alert.photo_path})


@csrf_exempt
@require_http_methods(["POST"])
def location_ping(request, user_id):
    user = _request_user(request)
    if user is None or user.id != user_id:
        return JsonResponse({"error": "Unauthorized."}, status=401)
    payload = _json_body(request)
    if payload is None:
        return _bad_request("Invalid JSON body.")
    try:
        latitude = Decimal(str(payload["latitude"]))
        longitude = Decimal(str(payload["longitude"]))
    except (KeyError, InvalidOperation):
        return _bad_request("latitude and longitude are required.")
    ping = LocationPing.objects.create(
        user=user,
        latitude=latitude,
        longitude=longitude,
    )
    return JsonResponse(
        {
            "id": ping.id,
            "latitude": str(ping.latitude),
            "longitude": str(ping.longitude),
            "recorded_at": ping.recorded_at.isoformat(),
        },
        status=201,
    )


@require_http_methods(["GET"])
def dashboard(request):
    recent_alerts = Alert.objects.select_related("user").prefetch_related(
        "notifications"
    )[:20]
    context = {
        "total_alerts": Alert.objects.count(),
        "triggered_alerts": Alert.objects.filter(status=Alert.Status.TRIGGERED).count(),
        "cancelled_alerts": Alert.objects.filter(status=Alert.Status.CANCELLED).count(),
        "queued_notifications": NotificationRecord.objects.filter(
            status=NotificationRecord.Status.QUEUED
        ).count(),
        "recent_alerts": recent_alerts,
        "latest_locations": LocationPing.objects.select_related("user")[:10],
    }
    return render(request, "alerts/dashboard.html", context)


@require_http_methods(["GET"])
def alert_detail(request, alert_id):
    alert = Alert.objects.select_related("user").prefetch_related(
        "notifications"
    ).filter(pk=alert_id).first()
    if alert is None:
        return JsonResponse({"error": "Alert not found."}, status=404)
    return render(request, "alerts/alert_detail.html", {"alert": alert})
