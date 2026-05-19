"""
Django settings for Vigil Backend — Production-grade configuration.
Security hardened, rate-limited, properly configured.
"""
import os
from pathlib import Path
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY: Always use environment variable in production
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'vigil-dev-insecure-change-me')

DEBUG = os.environ.get('DEBUG', 'True') == 'True'

ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Third party
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders',
    'django_filters',
    # Local apps
    'accounts',
    'contacts',
    'alerts',
    'location',
    'dashboard',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'vigil_backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'vigil_backend.wsgi.application'

# Database — PostgreSQL for production, SQLite for dev
if os.environ.get('DATABASE_URL'):
    import dj_database_url
    DATABASES = {'default': dj_database_url.parse(os.environ['DATABASE_URL'])}
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
     'OPTIONS': {'min_length': 8}},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

AUTH_USER_MODEL = 'accounts.VigilUser'

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Kolkata'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ═══════════════════════════════════════════════════════════
# REST Framework — with rate limiting and filtering
# ═══════════════════════════════════════════════════════════
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 25,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.OrderingFilter',
        'rest_framework.filters.SearchFilter',
    ],
    # Rate limiting — prevents brute force attacks
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '20/minute',     # Unauthenticated: 20 req/min
        'user': '120/minute',    # Authenticated: 120 req/min
        'login': '5/minute',     # Login attempts: 5/min (anti-brute-force)
        'alert_create': '10/minute',  # Alert creation: 10/min
        'location_update': '60/minute',  # Location: 60/min (1/sec max)
        'evidence_upload': '30/minute',  # Evidence upload: 30/min
    },
}

# ═══════════════════════════════════════════════════════════
# JWT Settings — Secure token configuration
# ═══════════════════════════════════════════════════════════
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=12),  # Reduced from 7 days
    'REFRESH_TOKEN_LIFETIME': timedelta(days=14),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'AUTH_HEADER_TYPES': ('Bearer',),
}

# ═══════════════════════════════════════════════════════════
# CORS — Strict in production
# ═══════════════════════════════════════════════════════════
CORS_ALLOW_ALL_ORIGINS = DEBUG
if not DEBUG:
    CORS_ALLOWED_ORIGINS = os.environ.get(
        'CORS_ORIGINS', 'https://vigil.app,https://api.vigil.app'
    ).split(',')
CORS_ALLOW_CREDENTIALS = True

# ═══════════════════════════════════════════════════════════
# Security headers (production)
# ═══════════════════════════════════════════════════════════
if not DEBUG:
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_SSL_REDIRECT = os.environ.get('SSL_REDIRECT', 'True') == 'True'
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

# ═══════════════════════════════════════════════════════════
# SMS Provider
# ═══════════════════════════════════════════════════════════
SMS_PROVIDER = os.environ.get('SMS_PROVIDER', 'msg91')
MSG91_AUTH_KEY = os.environ.get('MSG91_AUTH_KEY', '')
MSG91_SENDER_ID = os.environ.get('MSG91_SENDER_ID', 'VIGIL')
MSG91_TEMPLATE_ID = os.environ.get('MSG91_TEMPLATE_ID', '')
TWILIO_ACCOUNT_SID = os.environ.get('TWILIO_ACCOUNT_SID', '')
TWILIO_AUTH_TOKEN = os.environ.get('TWILIO_AUTH_TOKEN', '')
TWILIO_PHONE_NUMBER = os.environ.get('TWILIO_PHONE_NUMBER', '')

# SMS Retry settings
SMS_MAX_RETRIES = 3
SMS_RETRY_DELAY_SECONDS = 30

# ═══════════════════════════════════════════════════════════
# Email
# ═══════════════════════════════════════════════════════════
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.environ.get('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', 587))
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', 'Vigil Safety <noreply@vigil.app>')

# ═══════════════════════════════════════════════════════════
# File Upload Limits
# ═══════════════════════════════════════════════════════════
DATA_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB max upload
FILE_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024

# ═══════════════════════════════════════════════════════════
# Tracking Configuration
# ═══════════════════════════════════════════════════════════
TRACKING_BASE_URL = os.environ.get('TRACKING_BASE_URL', 'https://vigil.app')
MAX_LOCATION_HISTORY_DAYS = 30  # Auto-cleanup after 30 days
MAX_EVIDENCE_RETENTION_DAYS = 90  # Keep evidence for 90 days

# ═══════════════════════════════════════════════════════════
# Logging
# ═══════════════════════════════════════════════════════════
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '[{levelname}] {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
        'file': {
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'vigil.log',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'WARNING',
        },
        'alerts': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
        },
        'location': {
            'handlers': ['console'],
            'level': 'INFO',
        },
    },
}

# Create logs directory
(BASE_DIR / 'logs').mkdir(exist_ok=True)
