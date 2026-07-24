"""Simple in-memory rate limiter for authentication endpoints.

For production at scale, replace with Redis-backed rate limiting
(e.g., django-ratelimit or a custom Redis implementation).
"""

import time
from collections import defaultdict
from threading import Lock

from django.conf import settings


class RateLimiter:
    """Thread-safe sliding window rate limiter."""

    def __init__(self):
        self._attempts: dict[str, list[float]] = defaultdict(list)
        self._lock = Lock()

    def is_rate_limited(self, key: str) -> bool:
        """Check if the given key has exceeded the rate limit."""
        max_attempts = getattr(settings, 'RATE_LIMIT_LOGIN_ATTEMPTS', 5)
        window_seconds = getattr(settings, 'RATE_LIMIT_WINDOW_SECONDS', 300)
        now = time.time()
        cutoff = now - window_seconds

        with self._lock:
            # Remove expired entries
            self._attempts[key] = [
                ts for ts in self._attempts[key] if ts > cutoff
            ]
            return len(self._attempts[key]) >= max_attempts

    def record_attempt(self, key: str) -> None:
        """Record a failed authentication attempt."""
        with self._lock:
            self._attempts[key].append(time.time())

    def reset(self, key: str) -> None:
        """Reset attempts for a key after successful auth."""
        with self._lock:
            self._attempts.pop(key, None)


# Singleton instance
auth_rate_limiter = RateLimiter()


def get_client_ip(request) -> str:
    """Extract client IP from request, handling proxies."""
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        return x_forwarded_for.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR', '0.0.0.0')
