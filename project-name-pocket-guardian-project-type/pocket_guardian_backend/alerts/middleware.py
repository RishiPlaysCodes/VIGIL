"""Custom middleware for the Pocket Guardian API."""

import logging
import time

from django.http import JsonResponse

logger = logging.getLogger(__name__)


class RequestLoggingMiddleware:
    """Log request method, path, response status, and duration."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start = time.time()
        response = self.get_response(request)
        duration_ms = (time.time() - start) * 1000

        # Skip static file logging
        if not request.path.startswith("/static/"):
            logger.info(
                "%s %s %d (%.1fms)",
                request.method,
                request.path,
                response.status_code,
                duration_ms,
            )

        return response


class ContentLengthLimitMiddleware:
    """Reject requests with bodies larger than the configured limit.

    Prevents oversized payloads from consuming server resources.
    Default limit: 10MB (matches DATA_UPLOAD_MAX_MEMORY_SIZE).
    """

    MAX_BODY_SIZE = 10 * 1024 * 1024  # 10MB

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        content_length = request.META.get("CONTENT_LENGTH")
        if content_length:
            try:
                if int(content_length) > self.MAX_BODY_SIZE:
                    return JsonResponse(
                        {"error": "Request body too large."},
                        status=413,
                    )
            except (ValueError, TypeError):
                pass

        return self.get_response(request)


class SecurityHeadersMiddleware:
    """Add additional security headers to all responses."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        response["X-Content-Type-Options"] = "nosniff"
        response["X-Frame-Options"] = "DENY"
        response["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
        return response
